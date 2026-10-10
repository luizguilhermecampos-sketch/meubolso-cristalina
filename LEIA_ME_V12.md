# MeuBolso Cristalina V12 — Avaliações e painel administrativo

- Esta versão usa as tabelas `app_reviews`, `app_admins` e a função `meubolso_admin_summary` do SQL que você já executou com sucesso. **Não execute novamente o SQL apenas para atualizar o HTML.**
- Faça login com a conta administrativa autorizada; somente ela verá a aba Administrador. Não existe segunda senha.
- A aba Avaliações aceita nota entre 1 e 5 e comentário de 5 a 1000 caracteres. Cada conta tem uma avaliação que pode ser atualizada.
- O painel mostra total de usuários cadastrados, notas por estrela, média e comentários; exporta CSV.
- As despesas e salários de outros usuários não aparecem no painel administrativo. As políticas RLS e funções do Supabase são o mecanismo de proteção.
- Abra o `index.html` via Live Server. Teste com a conta administradora e outra conta comum. No painel, a contagem deve crescer quando outra conta se cadastrar.
- Ao enviar uma avaliação, confira em Table Editor > `app_reviews`. Uma avaliação já salva pode ser editada pelo próprio autor.
- O resumo conta usuários **cadastrados**, não usuários ativos. A listagem de comentários mostra até 1000 comentários recentes por vez, enquanto totais e notas são calculados no banco.
- O mapa mantém sua implementação anterior, sujeita à disponibilidade dos serviços gratuitos.
- Antes da divulgação pública, publique uma política de privacidade, implemente exclusão de conta e dados, teste redefinição de senha e revise segurança do aplicativo.
