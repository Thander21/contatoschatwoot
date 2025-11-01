# Gerenciador de Contatos Chatwoot

Aplicação Flutter Desktop para gerenciamento completo de contatos da plataforma Chatwoot, com funcionalidades de backup, formatação, remoção de duplicados, gerenciamento de empresas e validação de telefones brasileiros.

## 📋 Funcionalidades

### ✅ Implementadas

- **Dashboard com Estatísticas**: Visão geral de todos os contatos e problemas detectados
- **Sistema de Cache Inteligente**:
  - Carrega contatos uma vez e mantém em memória
  - Atualização automática entre telas
  - Reload manual apenas quando necessário
  - Elimina carregamentos desnecessários da API
- **Backup/Export para Excel**: Exporta todos os contatos para planilha Excel com timestamp
- **Formatação de Telefones em Lote**:
  - Adiciona código do país (+55)
  - Corrige formato antigo (remove 0 inicial)
  - Adiciona DDD padrão para números incompletos
  - Lista apenas telefones válidos (exclui inválidos que vão para tela específica)
  - Checkbox no lado esquerdo (padrão com outras telas)
  - Permite seleção individual ou em lote com "Selecionar Todos"
- **Validação e Limpeza de Telefones Inválidos**:
  - Valida números de telefone brasileiros (formato +55 + DDD + 8-9 dígitos)
  - Verifica DDDs válidos de todos os estados brasileiros
  - Identifica e explica motivos de invalidação (DDD inexistente, muito curto/longo, etc.)
  - Permite exclusão em massa de contatos com telefones inválidos
  - Interface com busca e seleção múltipla
- **Gerenciamento de Duplicados**:
  - Detecta contatos com telefones duplicados
  - Mantém o contato mais recente e completo
  - Permite seleção de quais grupos remover
  - Botões "Selecionar Todos" e "Desmarcar Todos"
- **Gerenciamento de Empresas**:
  - Extrai empresa do nome (padrão "Nome - Empresa")
  - Sugere empresas baseado no domínio do email
  - Permite edição manual das empresas
  - Preenche campo company nos contatos
  - Seleção em lote facilitada
- **Listagem Completa**: Lista todos os contatos com busca e filtros

## 🏗️ Arquitetura

### Estrutura de Pastas

```
lib/
├── main.dart                           # Ponto de entrada
├── contact_management_routes.dart      # Rotas da aplicação
├── models/
│   └── contact.dart                    # Modelo de dados Contact com parsing flexível
├── services/
│   ├── api_config.dart                 # Configurações da API
│   ├── contacts_service.dart           # Serviço de comunicação com API
│   ├── contacts_cache_service.dart     # Serviço de cache em memória (singleton)
│   ├── backup_service.dart             # Serviço de backup/export
│   ├── phone_formatter_service.dart    # Serviço de formatação e validação de telefone
│   ├── company_service.dart            # Serviço de gerenciamento de empresas
│   └── duplicates_service.dart         # Serviço de detecção de duplicados
└── screens/
    ├── dashboard_screen.dart           # Dashboard principal
    ├── contacts_list_screen.dart       # Lista completa de contatos
    ├── phone_format_screen.dart        # Tela de formatação de telefones
    ├── duplicate_contacts_screen.dart  # Tela de duplicados
    ├── company_management_screen.dart  # Tela de gerenciamento de empresas
    └── invalid_phones_screen.dart      # Tela de telefones inválidos (NEW)
```

### Padrões Utilizados

- **Service Layer**: Toda lógica de negócio está em serviços separados
- **Singleton Pattern**: Cache centralizado compartilhado entre todas as telas
- **Observer Pattern**: Listeners notificam mudanças no cache para atualização automática
- **Model-First**: Modelo de dados tipado para contatos com parsing flexível (int/String)
- **Stateful Screens**: Cada tela gerencia seu próprio estado
- **Async/Await**: Operações assíncronas para chamadas de API
- **Cache-First**: Carrega da API apenas quando necessário, prioriza cache em memória

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
2. **Apenas telefones VÁLIDOS** são listados (telefones inválidos vão para tela específica)
3. Filtre por tipo de problema (Sem +55, Formato antigo, etc)
4. Selecione os contatos usando checkbox à esquerda (individual ou "Selecionar Todos")
5. Clique em "Formatar" para aplicar correções
6. Aguarde a conclusão do processo
7. Telefones com DDD inválido ou formato incorreto não aparecem aqui

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
4. Use "Selecionar Todos" para processar em lote
5. As empresas serão extraídas e salvas no campo `company`

### Limpar Telefones Inválidos (NOVO)

1. Acesse "Telefones Inválidos" no dashboard
2. O sistema mostrará contatos com telefones que não seguem o padrão brasileiro:
   - DDDs inexistentes
   - Números muito curtos (menos de 10 dígitos)
   - Números muito longos (mais de 11 dígitos)
3. Use a busca para filtrar contatos específicos
4. Selecione contatos individuais ou use "Selecionar Todos"
5. Cada contato mostra o motivo da invalidação
6. Confirme a exclusão dos contatos selecionados
7. **ATENÇÃO**: Esta ação é irreversível - faça backup antes!

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
5. Cache apenas em memória (perdido ao fechar o app)

## 🆕 Melhorias Recentes

### Sistema de Cache (v2.0)
- Implementado `ContactsCacheService` singleton
- Elimina múltiplos carregamentos da API
- Atualização automática entre telas via listeners
- Carregamento manual controlado pelo usuário
- Parsing flexível de timestamps (int ou String)

### Validação de Telefones Brasileiros (v2.1)
- Nova tela "Telefones Inválidos"
- Validação completa de DDDs brasileiros (todos os estados)
- Explicação detalhada do motivo de invalidação
- Exclusão em massa com confirmação
- Interface com busca e seleção múltipla

### Melhorias de UX
- Botões "Selecionar Todos" e "Desmarcar Todos" em todas as telas de seleção múltipla
- Indicadores de progresso durante operações longas
- Mensagens de status detalhadas
- Sem auto-loading: app inicia instantaneamente

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
