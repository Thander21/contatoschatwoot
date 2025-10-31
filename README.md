# Gerenciador de Contatos Chatwoot

Aplicação Flutter Desktop para gerenciamento completo de contatos da plataforma Chatwoot, com funcionalidades de backup, formatação, remoção de duplicados e gerenciamento de empresas.

## 📋 Funcionalidades

### ✅ Implementadas

- **Dashboard com Estatísticas**: Visão geral de todos os contatos e problemas detectados
- **Backup/Export para Excel**: Exporta todos os contatos para planilha Excel com timestamp
- **Formatação de Telefones em Lote**:
  - Adiciona código do país (+55)
  - Corrige formato antigo (remove 0 inicial)
  - Adiciona DDD padrão para números incompletos
  - Permite seleção individual ou em lote
- **Gerenciamento de Duplicados**:
  - Detecta contatos com telefones duplicados
  - Mantém o contato mais recente e completo
  - Permite seleção de quais grupos remover
- **Gerenciamento de Empresas**:
  - Extrai empresa do nome (padrão "Nome - Empresa")
  - Sugere empresas baseado no domínio do email
  - Permite edição manual das empresas
  - Preenche campo company nos contatos
- **Listagem Completa**: Lista todos os contatos com busca e filtros

## 🏗️ Arquitetura

### Estrutura de Pastas

```
lib/
├── main.dart                           # Ponto de entrada
├── contact_management_routes.dart      # Rotas da aplicação
├── models/
│   └── contact.dart                    # Modelo de dados Contact
├── services/
│   ├── api_config.dart                 # Configurações da API
│   ├── contacts_service.dart           # Serviço de comunicação com API
│   ├── backup_service.dart             # Serviço de backup/export
│   ├── phone_formatter_service.dart    # Serviço de formatação de telefone
│   ├── company_service.dart            # Serviço de gerenciamento de empresas
│   └── duplicates_service.dart         # Serviço de detecção de duplicados
└── screens/
    ├── dashboard_screen.dart           # Dashboard principal
    ├── contacts_list_screen.dart       # Lista completa de contatos
    ├── phone_format_screen.dart        # Tela de formatação de telefones
    ├── duplicate_contacts_screen.dart  # Tela de duplicados
    └── company_management_screen.dart  # Tela de gerenciamento de empresas
```

### Padrões Utilizados

- **Service Layer**: Toda lógica de negócio está em serviços separados
- **Model-First**: Modelo de dados tipado para contatos
- **Stateful Screens**: Cada tela gerencia seu próprio estado
- **Async/Await**: Operações assíncronas para chamadas de API

## 🚀 Como Usar

### Pré-requisitos

- Flutter SDK 3.5.3 ou superior
- Dart SDK incluído no Flutter
- Windows/Linux/macOS (aplicação desktop)

### Instalação

1. Clone o repositório:
```bash
git clone <url-do-repo>
cd contatoschatwoot
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Execute a aplicação:
```bash
flutter run -d windows  # ou linux/macos
```

### Configuração da API

⚠️ **IMPORTANTE**: O token da API está hardcoded. Para produção, mova para arquivo `.env` ou configuração segura.

Edite `lib/services/api_config.dart`:
```dart
static const String baseUrl = 'https://seu-chatwoot.com.br/api/v1';
static const String apiToken = 'SEU_TOKEN_AQUI';
static const String accountId = '1';
```

## 📱 Guia de Uso

### Dashboard

A tela inicial mostra:
- Total de contatos carregados
- Quantidade de problemas por categoria
- Botões de ação rápida para cada funcionalidade

### Fazer Backup

1. No dashboard, clique em "Fazer Backup Completo"
2. O arquivo Excel será salvo em `Documents/backup_contatos_[timestamp].xlsx`
3. O arquivo contém: ID, Nome, Email, Telefone, Empresa, datas

### Corrigir Telefones

1. Acesse "Corrigir Telefones" no dashboard
2. Filtre por tipo de problema (Sem +55, Formato antigo, etc)
3. Selecione os contatos desejados (individual ou todos)
4. Clique em "Formatar" para aplicar correções
5. Aguarde a conclusão do processo

### Remover Duplicados

1. Acesse "Limpar Duplicados"
2. Visualize grupos de contatos com mesmo telefone
3. Selecione os grupos que deseja processar
4. O sistema manterá automaticamente o contato mais recente
5. Confirme a exclusão

### Gerenciar Empresas

1. Acesse "Gerenciar Empresas"
2. Filtre por:
   - Todos: Contatos sem empresa
   - Com sugestão: Sistema sugeriu empresa baseado em email
   - Empresa no nome: Tem padrão "Nome - Empresa"
3. Edite manualmente a empresa de cada contato
4. Selecione e processe em lote
5. As empresas serão extraídas e salvas no campo `company`

## 🔧 Manutenção

### Adicionar Nova Funcionalidade

1. Crie o serviço em `lib/services/`
2. Crie a tela em `lib/screens/`
3. Adicione a rota em `contact_management_routes.dart`
4. Adicione botão no dashboard

### Modificar Padrões de Empresa

Edite `lib/services/company_service.dart`:
```dart
static final _companyPatterns = [
  RegExp(r'\s+-\s+(.+)$'),    // "Nome - Empresa"
  RegExp(r'\s+\((.+)\)$'),    // "Nome (Empresa)"
  // Adicione novos padrões aqui
];
```

### Alterar DDD Padrão

Edite `lib/services/phone_formatter_service.dart`:
```dart
String formatPhoneNumber(String phone, {String defaultDDD = '11'}) {
  // Altere '11' para o DDD desejado
}
```

## 📊 Estatísticas e Logs

A aplicação usa `package:logging` para logs detalhados:
- Todas as operações são registradas
- Erros incluem stack trace completo
- Logs aparecem no console durante desenvolvimento

## ⚠️ Limitações Conhecidas

1. Token da API hardcoded (precisa ser movido para configuração segura)
2. Sem autenticação de usuário
3. Sem histórico de operações (undo/redo)
4. Sem validação de regras de negócio customizadas
5. Paginação carrega todas as páginas (pode ser lento com muitos contatos)

## 🔐 Segurança

**ATENÇÃO**: Esta é uma aplicação de uso único/interno. Para produção:

1. ✅ Mova token para variável de ambiente
2. ✅ Adicione autenticação de usuário
3. ✅ Implemente rate limiting nas chamadas de API
4. ✅ Valide todas as entradas de usuário
5. ✅ Adicione logs de auditoria

## 📦 Dependências Principais

```yaml
dependencies:
  flutter: sdk
  http: ^1.1.0              # Chamadas HTTP
  excel: ^4.0.6             # Exportação Excel
  path_provider: ^2.1.1     # Acesso a diretórios
  window_manager: ^0.5.1    # Gerenciamento de janela desktop
  logging: ^1.2.0           # Sistema de logs
  intl: ^0.20.2            # Formatação de datas
```

## 🐛 Resolução de Problemas

### Erro ao carregar contatos
- Verifique a URL da API em `api_config.dart`
- Confirme que o token está correto
- Verifique conexão com internet

### Erro ao salvar backup
- Verifique permissões de escrita em `Documents`
- Confirme espaço em disco disponível

### Contatos não estão sendo atualizados
- Confirme que o ID do contato existe
- Verifique logs para detalhes do erro
- Teste a API diretamente (Postman/cURL)

## 📝 Licença

Este projeto é de uso interno. Todos os direitos reservados.

## 👥 Contribuindo

Para contribuir:
1. Crie uma branch para sua feature
2. Faça commit das mudanças
3. Abra um Pull Request
4. Aguarde revisão

## 📞 Suporte

Para dúvidas ou problemas:
- Abra uma issue no repositório
- Consulte a documentação da API Chatwoot
- Verifique os logs da aplicação
