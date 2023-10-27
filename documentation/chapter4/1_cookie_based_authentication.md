
#### Autenticazione basata su cookie
Per identificare in modo sicuro l'utente dietro a una richiesta, il loro ID utente e un token di sessione generato casualmente saranno memorizzati in un cookie cifrato. In questo modo, le informazioni non possono essere visualizzate o manomesse da utenti malintenzionati.

Quando arriva una richiesta, l'ID utente e il token di sessione vengono estratti dal cookie e confrontati con il database per identificare in modo sicuro l'utente. Se l'autenticazione ha successo, il ciclo della richiesta continua; in caso contrario, verrà visualizzata la pagina di accesso.

![Autenticazione basata sui cookie - Shopping Gioioso](/documentation/chapter4/images/cookie_based_authentication.png "Il flusso per memorizzare e convalidare in modo sicuro le informazioni in un cookie per autenticare una richiesta")


