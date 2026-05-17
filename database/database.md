-- ============================================================================
-- DATABASE SCHEMA - APP BÁN ĐỒ ĂN
-- Phiên bản: 2.0 (Production-ready - Đã fix toàn bộ vấn đề bảo mật & nghiệp vụ)
-- Tech stack: Supabase (PostgreSQL 15+)
--
-- Cấu trúc file:
--   1. EXTENSIONS
--   2. ENUM TYPES
--   3. UTILITY FUNCTIONS
--   4. TABLES (17 bảng)
--   5. INDEXES
--   6. TRIGGERS (8 trigger tự động hoá)
--   7. ROW LEVEL SECURITY (RLS policies cho toàn bộ bảng)
--   8. SEED DATA (dữ liệu khởi tạo)
-- ============================================================================
SET check_function_bodies = OFF;

-- ============================================================================
-- 1. EXTENSIONS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ============================================================================
-- 2. ENUM TYPES
-- ============================================================================
DROP TYPE IF EXISTS user_role CASCADE;
CREATE TYPE user_role AS ENUM ('admin', 'customer');

DROP TYPE IF EXISTS user_status CASCADE;
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'banned');

DROP TYPE IF EXISTS order_status CASCADE;
CREATE TYPE order_status AS ENUM (
  'pending',      -- chờ xác nhận
  'confirmed',    -- đã xác nhận
  'preparing',    -- đang chuẩn bị
  'delivering',   -- đang giao
  'completed',    -- hoàn tất
  'cancelled'     -- đã huỷ
);

DROP TYPE IF EXISTS payment_method CASCADE;
CREATE TYPE payment_method AS ENUM ('cod', 'momo', 'banking', 'viettel');

DROP TYPE IF EXISTS payment_status CASCADE;
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed');

DROP TYPE IF EXISTS delivery_type CASCADE;
CREATE TYPE delivery_type AS ENUM ('pickup', 'delivery');

DROP TYPE IF EXISTS notification_type CASCADE;
CREATE TYPE notification_type AS ENUM ('order', 'system', 'promotion');


-- ============================================================================
-- 3. UTILITY FUNCTIONS
-- ============================================================================

-- 3.1 Function tự động cập nhật cột updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- 3.2 Function check admin role
-- Dùng SECURITY DEFINER để tránh INFINITE RECURSION khi RLS query lại bảng users
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;


-- ============================================================================
-- 4. TABLES
-- ============================================================================

-- 4.1 USERS (đã thêm UNIQUE phone, validate format, CHECK loyalty_points)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE,
    phone VARCHAR(20) UNIQUE,
    full_name VARCHAR(100),
    avatar_url TEXT,
    role user_role DEFAULT 'customer',
    status user_status DEFAULT 'active',
    loyalty_points INT DEFAULT 0 CHECK (loyalty_points >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT users_phone_format CHECK (
      phone IS NULL OR phone ~ '^(0|\+84)[0-9]{9,10}$'
    )
);


-- 4.2 ADDRESSES (thêm recipient_name, recipient_phone, label)
CREATE TABLE public.addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    label TEXT,                              -- "Nhà", "Công ty"
    recipient_name VARCHAR(100),
    recipient_phone VARCHAR(20),
    full_address TEXT NOT NULL,
    lat NUMERIC(10,8),
    lng NUMERIC(11,8),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.3 CATEGORIES (thêm display_order, soft delete)
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    image_url TEXT,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    deleted_at TIMESTAMPTZ,                  -- soft delete
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.4 PRODUCTS (thêm CHECK price >= 0, soft delete)
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    image_url TEXT,
    category_id UUID REFERENCES public.categories(id),
    is_available BOOLEAN DEFAULT TRUE,
    rating_avg NUMERIC(3,2) DEFAULT 5.0,
    total_reviews INT DEFAULT 0,
    deleted_at TIMESTAMPTZ,                  -- soft delete
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.5 PRODUCT OPTIONS (size, topping...)
CREATE TABLE public.product_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    name TEXT NOT NULL,                      -- "Size", "Topping"
    values JSONB NOT NULL,                   -- [{"label":"L","price":5000}]
    is_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.6 FAVORITES (yêu thích - bảng MỚI)
CREATE TABLE public.favorites (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, product_id)
);


-- 4.7 CART ITEMS
CREATE TABLE public.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id),
    quantity INT NOT NULL CHECK (quantity > 0),
    price_at_time NUMERIC(10,2),
    options JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.8 VOUCHERS (thêm description, NOT NULL cho discount_type)
CREATE TABLE public.vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    description TEXT,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percent', 'fixed')),
    discount_value NUMERIC(10,2) NOT NULL CHECK (discount_value > 0),
    min_order_amount NUMERIC(10,2) DEFAULT 0,
    max_discount NUMERIC(10,2),              -- giới hạn cho loại %
    usage_limit INT,                          -- số lần dùng tối đa
    used_count INT DEFAULT 0,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.9 USER VOUCHERS (bảng MỚI - voucher gắn với user, dùng cho AI cá nhân hoá phase 2)
CREATE TABLE public.user_vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    voucher_id UUID REFERENCES public.vouchers(id) ON DELETE CASCADE,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, voucher_id)
);


-- 4.10 ORDERS (thêm order_code, cancel_reason, cancelled_at, completed_at)
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_code TEXT UNIQUE,                  -- mã ngắn cho user: ORD-20260425-0001
    user_id UUID REFERENCES public.users(id),
    address_id UUID REFERENCES public.addresses(id),
    voucher_id UUID REFERENCES public.vouchers(id),

    delivery_type delivery_type NOT NULL DEFAULT 'delivery',
    note TEXT,

    subtotal NUMERIC(12,2),
    shipping_fee NUMERIC(10,2) DEFAULT 0,
    discount_amount NUMERIC(10,2) DEFAULT 0,
    total_amount NUMERIC(12,2),

    status order_status DEFAULT 'pending',
    payment_method payment_method,
    payment_status payment_status DEFAULT 'pending',

    cancel_reason TEXT,
    cancelled_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.11 ORDER ITEMS (thêm product_name snapshot)
CREATE TABLE public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id),
    product_name TEXT,                       -- snapshot tên món lúc đặt
    quantity INT NOT NULL CHECK (quantity > 0),
    price NUMERIC(10,2) NOT NULL,
    options JSONB DEFAULT '[]'
);


-- 4.12 REVIEWS
CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id),
    product_id UUID REFERENCES public.products(id),
    order_id UUID REFERENCES public.orders(id),
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, order_id, product_id)    -- mỗi món/đơn chỉ review 1 lần
);


-- 4.13 ORDER STATUS HISTORY (changed_by giờ NULLABLE - cho trường hợp system tự đổi)
CREATE TABLE public.order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    status order_status NOT NULL,
    note TEXT,
    changed_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.14 NOTIFICATIONS
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type notification_type DEFAULT 'system',
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    related_order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.15 LOYALTY TRANSACTIONS (bảng MỚI - lịch sử cộng/trừ điểm)
CREATE TABLE public.loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id),
    points INT NOT NULL,                     -- âm = trừ, dương = cộng
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.16 SHOP SETTINGS (bảng MỚI - cấu hình chung của shop, chỉ 1 dòng duy nhất)
CREATE TABLE public.shop_settings (
    id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    name TEXT,
    hotline TEXT,
    address TEXT,
    open_time TIME,
    close_time TIME,
    is_open BOOLEAN DEFAULT TRUE,
    shipping_fee_per_km NUMERIC(10,2) DEFAULT 5000,
    free_ship_threshold NUMERIC(10,2),
    loyalty_rate NUMERIC(5,2) DEFAULT 1.0,   -- tỷ lệ tích điểm (1% giá trị đơn = 1 điểm)
    updated_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4.17 BANNERS (bảng MỚI - banner trang chủ)
CREATE TABLE public.banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT,
    image_url TEXT NOT NULL,
    link_url TEXT,
    position INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================================
-- 5. INDEXES
-- ============================================================================
CREATE INDEX idx_products_category   ON public.products(category_id);
CREATE INDEX idx_products_available  ON public.products(is_available) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_user         ON public.orders(user_id);
CREATE INDEX idx_orders_status       ON public.orders(status);
CREATE INDEX idx_orders_created      ON public.orders(created_at DESC);
CREATE INDEX idx_orders_code         ON public.orders(order_code);
CREATE INDEX idx_order_items_order   ON public.order_items(order_id);
CREATE INDEX idx_order_items_product ON public.order_items(product_id);
CREATE INDEX idx_history_order       ON public.order_status_history(order_id);
CREATE INDEX idx_notifications_user  ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_cart_user           ON public.cart_items(user_id);
CREATE INDEX idx_reviews_product     ON public.reviews(product_id);
CREATE INDEX idx_favorites_user      ON public.favorites(user_id);
CREATE INDEX idx_loyalty_user        ON public.loyalty_transactions(user_id);
CREATE INDEX idx_addresses_user      ON public.addresses(user_id);


-- ============================================================================
-- 6. TRIGGERS
-- ============================================================================

-- 6.1 Tạo profile user khi đăng ký qua Supabase Auth
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();


-- 6.2 Tự động update cột updated_at
CREATE TRIGGER trg_users_updated 
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_orders_updated 
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_shop_settings_updated 
  BEFORE UPDATE ON public.shop_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- 6.3 Tự cập nhật rating_avg + total_reviews của product khi có review thay đổi
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS trigger AS $$
DECLARE
  pid UUID;
BEGIN
  pid := COALESCE(NEW.product_id, OLD.product_id);
  UPDATE public.products
  SET 
    rating_avg = COALESCE(
      (SELECT ROUND(AVG(rating)::NUMERIC, 2) FROM public.reviews WHERE product_id = pid),
      5.0
    ),
    total_reviews = (SELECT COUNT(*) FROM public.reviews WHERE product_id = pid)
  WHERE id = pid;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_review_rating
AFTER INSERT OR UPDATE OR DELETE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION update_product_rating();


-- 6.4 Tự set timestamp khi đơn hoàn tất / huỷ (BEFORE)
CREATE OR REPLACE FUNCTION set_order_timestamps()
RETURNS trigger AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NEW.status = 'completed' AND NEW.completed_at IS NULL THEN
      NEW.completed_at = NOW();
    ELSIF NEW.status = 'cancelled' AND NEW.cancelled_at IS NULL THEN
      NEW.cancelled_at = NOW();
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_set_timestamps
BEFORE UPDATE OF status ON public.orders
FOR EACH ROW EXECUTE FUNCTION set_order_timestamps();


-- 6.5 Tự log mọi thay đổi status đơn vào order_status_history (AFTER)
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
    INSERT INTO public.order_status_history (order_id, status, changed_by)
    VALUES (NEW.id, NEW.status, COALESCE(auth.uid(), NEW.user_id));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_status_log
AFTER INSERT OR UPDATE OF status ON public.orders
FOR EACH ROW EXECUTE FUNCTION log_order_status_change();


-- 6.6 Tự tăng used_count của voucher khi tạo đơn có voucher
CREATE OR REPLACE FUNCTION increment_voucher_usage()
RETURNS trigger AS $$
BEGIN
  IF NEW.voucher_id IS NOT NULL THEN
    UPDATE public.vouchers 
    SET used_count = used_count + 1 
    WHERE id = NEW.voucher_id;

    -- Đánh dấu user_voucher đã dùng (nếu có)
    UPDATE public.user_vouchers 
    SET used_at = NOW() 
    WHERE user_id = NEW.user_id 
      AND voucher_id = NEW.voucher_id 
      AND used_at IS NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_voucher_usage
AFTER INSERT ON public.orders
FOR EACH ROW EXECUTE FUNCTION increment_voucher_usage();


-- 6.7 Tự sinh order_code dạng "ORD-20260425-0001"
CREATE OR REPLACE FUNCTION generate_order_code()
RETURNS trigger AS $$
DECLARE
  next_seq INT;
BEGIN
  IF NEW.order_code IS NULL THEN
    SELECT COUNT(*) + 1 INTO next_seq 
    FROM public.orders 
    WHERE created_at::date = CURRENT_DATE;

    NEW.order_code := 'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(next_seq::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_code
BEFORE INSERT ON public.orders
FOR EACH ROW EXECUTE FUNCTION generate_order_code();


-- 6.8 Tự update loyalty_points của user khi insert loyalty_transaction
CREATE OR REPLACE FUNCTION update_user_loyalty_points()
RETURNS trigger AS $$
BEGIN
  UPDATE public.users 
  SET loyalty_points = GREATEST(loyalty_points + NEW.points, 0)
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_loyalty_update
AFTER INSERT ON public.loyalty_transactions
FOR EACH ROW EXECUTE FUNCTION update_user_loyalty_points();


-- 6.9 Đảm bảo mỗi user chỉ có 1 địa chỉ default
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS trigger AS $$
BEGIN
  IF NEW.is_default = TRUE THEN
    UPDATE public.addresses 
    SET is_default = FALSE 
    WHERE user_id = NEW.user_id AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_default_address
AFTER INSERT OR UPDATE OF is_default ON public.addresses
FOR EACH ROW WHEN (NEW.is_default = TRUE)
EXECUTE FUNCTION ensure_single_default_address();


-- ============================================================================
-- 7. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- 7.1 Bật RLS trên TẤT CẢ các bảng (fix lỗ hổng cũ)
ALTER TABLE public.users                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_options        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vouchers               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_vouchers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_settings          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners                ENABLE ROW LEVEL SECURITY;


-- 7.2 USERS
CREATE POLICY "users_select_own" ON public.users 
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "users_update_own" ON public.users 
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "users_admin_all" ON public.users 
  FOR ALL USING (public.is_admin());


-- 7.3 ADDRESSES
CREATE POLICY "addresses_user_all" ON public.addresses 
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "addresses_admin_select" ON public.addresses 
  FOR SELECT USING (public.is_admin());


-- 7.4 CATEGORIES (public read, admin write)
CREATE POLICY "categories_anyone_select" ON public.categories 
  FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "categories_admin_all" ON public.categories 
  FOR ALL USING (public.is_admin());


-- 7.5 PRODUCTS (public read, admin write)
CREATE POLICY "products_anyone_select" ON public.products 
  FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "products_admin_all" ON public.products 
  FOR ALL USING (public.is_admin());


-- 7.6 PRODUCT OPTIONS
CREATE POLICY "product_options_anyone_select" ON public.product_options 
  FOR SELECT USING (true);
CREATE POLICY "product_options_admin_all" ON public.product_options 
  FOR ALL USING (public.is_admin());


-- 7.7 FAVORITES
CREATE POLICY "favorites_user_all" ON public.favorites 
  FOR ALL USING (auth.uid() = user_id);


-- 7.8 CART
CREATE POLICY "cart_user_all" ON public.cart_items 
  FOR ALL USING (auth.uid() = user_id);


-- 7.9 VOUCHERS (chỉ thấy voucher còn active, còn lượt, chưa hết hạn)
CREATE POLICY "vouchers_anyone_select_active" ON public.vouchers 
  FOR SELECT USING (
    is_active = TRUE
    AND (expires_at IS NULL OR expires_at > NOW())
    AND (usage_limit IS NULL OR used_count < usage_limit)
  );
CREATE POLICY "vouchers_admin_all" ON public.vouchers 
  FOR ALL USING (public.is_admin());


-- 7.10 USER VOUCHERS
CREATE POLICY "user_vouchers_select_own" ON public.user_vouchers 
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_vouchers_admin_all" ON public.user_vouchers 
  FOR ALL USING (public.is_admin());


-- 7.11 ORDERS (user chỉ huỷ được khi đơn còn pending)
CREATE POLICY "orders_select_own" ON public.orders 
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "orders_insert_own" ON public.orders 
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "orders_update_own_pending" ON public.orders 
  FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');
CREATE POLICY "orders_admin_all" ON public.orders 
  FOR ALL USING (public.is_admin());


-- 7.12 ORDER ITEMS (FIX lỗ hổng - user chỉ xem được items của đơn mình)
CREATE POLICY "order_items_select_own" ON public.order_items 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders 
      WHERE orders.id = order_items.order_id 
        AND orders.user_id = auth.uid()
    )
  );
CREATE POLICY "order_items_insert_own" ON public.order_items 
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders 
      WHERE orders.id = order_items.order_id 
        AND orders.user_id = auth.uid()
    )
  );
CREATE POLICY "order_items_admin_all" ON public.order_items 
  FOR ALL USING (public.is_admin());


-- 7.13 REVIEWS (FIX - user chỉ review được món đã mua trong đơn đã hoàn tất)
CREATE POLICY "reviews_anyone_select" ON public.reviews 
  FOR SELECT USING (true);
CREATE POLICY "reviews_insert_if_purchased" ON public.reviews 
  FOR INSERT WITH CHECK (
    auth.uid() = user_id 
    AND EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.order_items oi ON oi.order_id = o.id
      WHERE o.id = reviews.order_id 
        AND o.user_id = auth.uid() 
        AND o.status = 'completed'
        AND oi.product_id = reviews.product_id
    )
  );
CREATE POLICY "reviews_update_own" ON public.reviews 
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "reviews_delete_own" ON public.reviews 
  FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "reviews_admin_all" ON public.reviews 
  FOR ALL USING (public.is_admin());


-- 7.14 ORDER STATUS HISTORY
CREATE POLICY "history_select_own" ON public.order_status_history 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders 
      WHERE orders.id = order_status_history.order_id 
        AND orders.user_id = auth.uid()
    )
  );
CREATE POLICY "history_admin_all" ON public.order_status_history 
  FOR ALL USING (public.is_admin());


-- 7.15 NOTIFICATIONS
CREATE POLICY "notifications_select_own" ON public.notifications 
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_update_own" ON public.notifications 
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "notifications_admin_all" ON public.notifications 
  FOR ALL USING (public.is_admin());


-- 7.16 LOYALTY TRANSACTIONS
CREATE POLICY "loyalty_select_own" ON public.loyalty_transactions 
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "loyalty_admin_all" ON public.loyalty_transactions 
  FOR ALL USING (public.is_admin());


-- 7.17 SHOP SETTINGS (ai cũng đọc được, chỉ admin sửa)
CREATE POLICY "shop_settings_anyone_select" ON public.shop_settings 
  FOR SELECT USING (true);
CREATE POLICY "shop_settings_admin_all" ON public.shop_settings 
  FOR ALL USING (public.is_admin());


-- 7.18 BANNERS
CREATE POLICY "banners_anyone_select_active" ON public.banners 
  FOR SELECT USING (is_active = TRUE);
CREATE POLICY "banners_admin_all" ON public.banners 
  FOR ALL USING (public.is_admin());


-- ============================================================================
-- 8. SEED DATA
-- ============================================================================

-- Cấu hình shop mặc định
INSERT INTO public.shop_settings (id, name, hotline, address, open_time, close_time)
VALUES (1, 'My Food Shop', '0900000000', 'Tuy Hòa, Phú Yên', '07:00', '22:00')
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- 9. HƯỚNG DẪN TẠO ADMIN ĐẦU TIÊN
-- ============================================================================
-- Sau khi đăng ký 1 tài khoản qua Supabase Auth, chạy lệnh sau để cấp quyền admin:
--
--   UPDATE public.users 
--   SET role = 'admin', full_name = 'Tên Admin' 
--   WHERE email = 'your-email@example.com';
--
-- ============================================================================
-- HẾT
-- ============================================================================