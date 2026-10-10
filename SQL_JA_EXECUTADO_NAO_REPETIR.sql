-- MeuBolso Cristalina - Avaliações e painel administrativo
-- Execute no SQL Editor do projeto Supabase do MeuBolso.
-- Não modifica a tabela member_finances.
-- Corrigido: UID conferido na tela Authentication > Users.

BEGIN;

CREATE TABLE IF NOT EXISTS public.app_admins (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.app_admins ENABLE ROW LEVEL SECURITY;

-- A tabela de administradores não é administrável pelo cliente.
REVOKE ALL ON public.app_admins FROM anon, authenticated;

-- A autorização é sempre conferida no banco, nunca apenas no HTML.
CREATE OR REPLACE FUNCTION public.meubolso_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.app_admins
    WHERE user_id = (SELECT auth.uid())
  );
$$;
REVOKE ALL ON FUNCTION public.meubolso_is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.meubolso_is_admin() TO authenticated;

CREATE TABLE IF NOT EXISTS public.app_reviews (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stars smallint NOT NULL CHECK (stars BETWEEN 1 AND 5),
  comment text NOT NULL CHECK (char_length(btrim(comment)) BETWEEN 5 AND 2000),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT one_review_per_user UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS app_reviews_created_at_idx ON public.app_reviews(created_at DESC);
ALTER TABLE public.app_reviews ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE ON public.app_reviews TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.app_reviews_id_seq TO authenticated;

DROP POLICY IF EXISTS "Read own review or admin" ON public.app_reviews;
CREATE POLICY "Read own review or admin" ON public.app_reviews
FOR SELECT TO authenticated
USING (user_id = (SELECT auth.uid()) OR (SELECT public.meubolso_is_admin()));

DROP POLICY IF EXISTS "Insert own review" ON public.app_reviews;
CREATE POLICY "Insert own review" ON public.app_reviews
FOR INSERT TO authenticated
WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Update own review" ON public.app_reviews;
CREATE POLICY "Update own review" ON public.app_reviews
FOR UPDATE TO authenticated
USING (user_id = (SELECT auth.uid()))
WITH CHECK (user_id = (SELECT auth.uid()));

-- Esta função retorna somente números agregados a administradores.
CREATE OR REPLACE FUNCTION public.meubolso_admin_summary()
RETURNS TABLE (
  registered_users bigint,
  reviews_count bigint,
  average_stars numeric,
  stars_1 bigint,
  stars_2 bigint,
  stars_3 bigint,
  stars_4 bigint,
  stars_5 bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF (SELECT auth.uid()) IS NULL OR NOT public.meubolso_is_admin() THEN
    RAISE EXCEPTION 'Acesso não autorizado' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY SELECT
    (SELECT count(*) FROM auth.users)::bigint,
    count(*)::bigint,
    round(avg(r.stars::numeric), 2),
    count(*) FILTER (WHERE r.stars = 1)::bigint,
    count(*) FILTER (WHERE r.stars = 2)::bigint,
    count(*) FILTER (WHERE r.stars = 3)::bigint,
    count(*) FILTER (WHERE r.stars = 4)::bigint,
    count(*) FILTER (WHERE r.stars = 5)::bigint
  FROM public.app_reviews AS r;
END;
$$;
REVOKE ALL ON FUNCTION public.meubolso_admin_summary() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.meubolso_admin_summary() TO authenticated;

-- Autoriza exclusivamente a conta informada em Authentication > Users.
DO $$
DECLARE
  target_user uuid := '5331d709-c10d-4321-b2f2-45024f8fdfab';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = target_user) THEN
    RAISE EXCEPTION 'UID de administrador não encontrado em auth.users. Verifique Authentication > Users.';
  END IF;
  INSERT INTO public.app_admins (user_id)
  VALUES (target_user)
  ON CONFLICT (user_id) DO NOTHING;
END $$;

COMMIT;

-- Verificação, executada no editor privilegiado (não pelo HTML):
SELECT user_id, created_at FROM public.app_admins;
