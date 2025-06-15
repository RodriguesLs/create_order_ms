# README Create Order Sentry Micro-service

Este micro-serviço foi desenvolvido para melhorar o processo de criação de pedidos no sentry-hub (interface de integração entre a ExternalAPI e a empresa Rodrigues).

* Informações úteis:

- Ruby version: 3.4
- Rails version: 7.1
- Banco de dados: PostgreSQL 15

* Configurações

Para rodar o projeto basta ter o Docker e o docker-compose devidamente instalados. O projeto foi desenhado desde o princípio para ser facilmente inicializado usando a tecnologia de containers. O banco de dados não precisa ser criado ou configurado, isso será feito automaticamente quando a aplicação for inicializada.

* Como rodar os testes

bundle exec rspec

* Aplication Flow

1. Recebimento do hook externo (/webhooks/order)
2. Validação do hook e chamada da API externa para obter dados completos do pedido
  a. Reprocessamento de pedidos caso o status não seja o esperado para prosseguimento do fluxo
3. Transformação do dado, persistência de Logs para tracking
4. Envio de dados formatados para API principal que lida com os detalhes de persistência do pedido
