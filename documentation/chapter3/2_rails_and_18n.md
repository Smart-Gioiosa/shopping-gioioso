# Rails e I18n

Prima di creare il modulo di registrazione, facciamo una breve deviazione e discutiamo di `internazionalizzazione (I18n)` e `localizzazione (L18n)`. 
#ShoppingGioioso verrà internazionalizzato fin dall'inizio. Ciò significa che tutto il testo rivolto agli utenti verrà astratto dalla nostra applicazione e inserito in `dizionari di localizzazione` in modo che l'applicazione possa essere utilizzata in diverse lingue.

Costruiremo in inglese questo progetto,predisponendo l'applicazione per la lingua `Ìtaliana`.

Internazionalizzazione fin dall'inizio ha molti vantaggi. Mantiene tutto il testo rivolto agli utenti fuori dai controller e dalle viste, rendendo più facile vedere l'essenziale. Mentre scriviamo `test`, possiamo fare un'asserzione per la chiave nel `dizionario delle localizzazioni` anziché per il testo stesso, il che significa che i `test` sono robusti quando cambia il testo rivolto agli utenti. 

L'`internazionalizzazione (I18n)` in Rails è fornita dalla `gemma Ruby I18n`. Tutte le applicazioni Rails hanno una configurazione `I18n` di base già pronta. Il testo rivolto agli utenti viene inserito in  un file `YAML` nella cartella `config/locales/` con il `codice ISO` della lingua come chiave radice.

*Esempio di un dizionario locale:*

```ruby
en:
    hello: Hello World!
    goodbye: Goodbye.
```

Queste stringhe possono essere richiamate nel codice utilizzando il metodo `translate` o la forma abbreviata `t`. Possimamo fare una prova, aprendo la console di rails, tramite il comando `rails c` e lanciare il metodo `translate`, come segue: 

```ruby
I18n.translate "hello"
# => "Hello World!"

I18n.t "goodbye"
# => "Goodbye."

```
Dal punto di vista concettuale, è tutto qui! `I18n` utilizza `:en` come lingua predefinita, quindi non è necessaria alcuna configurazione fino a quando non vengono aggiunte più lingue.

## Stringhe localizzate nelle `viste` e nei `controller`

La chiave per una stringa localizzata può essere dedotta dal contesto quando si chiama `t` in un `controller` o una `vista`, come segue:

```ruby
class UsersController < ApplicationController
# ...
    def create
    #...
        redirect_to home_path, notice: t(".success")
    #...
    end
# ...
end  
```

Il modulo `I18n` non deve essere specificato quando si chiama `t` in un `controller` o una `vista`.

Possiamo notare anche che la chiave ha un punto `(.)` come prefisso. Questo dice a `Rails` di dedurre la chiave completa dal contesto e si espanderà a `users.create.success`. Per convenzione, il nome del `controller` e dell'`azione` sono separati da un punto, così un (.)  viene anteposto alla chiave fornita.
La stessa logica si applica anche nei file di visualizzazione. In questo modo, i nomi delle chiavi rimangono concisi!

## Localizzazione in `Active Record`

Gli attributi di `Active Record` vengono spesso utilizzati nell'interfaccia utente in `Rails`. Ad esempio, un tipico modulo Rails appare come segue:

```ruby
<%= form_with(model: @user) do |form| %>
    <%= form.label :name %>
    <%= form.text_field :name %>

    <%= form.label :email %>
    <%= form.email_field :email %>
<% end %>
```

`name` ed `email` sono attributi nel modello `User`. Un modo per `localizzare` questi termini è passare esplicitamente un valore:

```ruby
<%= form.label :name, value: t(".name") %>
```

Ma questo approccio porterà a duplicazioni nei dizionari di localizzazione ed è noioso da gestire. C'è un modo migliore. `Active Record` dispone di funzionalità di localizzazione integrate per gli attributi del modello e persino per il nome del modello stesso. Le traduzioni possono essere archiviate sotto la chiave `activerecord` e saranno rilevate dai metodi di traduzione.

Supponiamo volessimo presentare il modello `User` come `Person` nell'interfaccia utente e localizzare tutti i suoi attributi. Il dizionario delle localizzazioni apparirebbe come segue:

```ruby
en:
    activerecord:
        models:
            user: Person
        attributes:
            user:
                name: Name
                email: Email
                password: Password

```
I seguenti metodi possono essere utilizzati per accedere a queste traduzioni:

```ruby
User.model_name.human
# => "Person"

User.human_attribute_name(:name)
# => "Name"

```

Ecco come `Active Record` si collega direttamente alla localizzazione e non è necessario alcun codice aggiuntivo per localizzare i modelli e i loro attributi. Gli `helper` per i `form` utilizzano in modo conveniente questi metodi di traduzione dietro le quinte!

Questa tecnica è anche utile quando il valore rivolto all'utente di un modello o di un attributo è diverso da come è chiamato nel database.

## Struttura delle cartelle per il dizionario di localizzazione.

Come menzionato in precedenza, i dizionari di localizzazione vanno nella cartella `config/locales/`. Teoricamente, potremmo mettere tutte le stringhe in un unico file enorme, ma ciò renderebbe impossibile la manutenzione. In questo caso, `Rails` non impone una struttura specifica, quindi è prudente seguire alcune regole di base per l'organizzazione.


Prendendo ispirazione dalla struttura delle cartelle sotto `app/`, creeremo due cartelle chiamate `views` e `models` sotto `config/locales/`. In queste cartelle, creeremo sottocartelle per ciascun `modello` o `controller`, e al loro interno creeremo file `.yml` per ciascuna lingua. Come esempio, per un modello `User` e un `UsersController`, la struttura delle cartelle sarebbe simile a:

```
locales/
|- models/
|-- user/
|     |-- en.yml
|     |-- it.yml
|- views/
|-- users/
|     |-- en.yml
|     |-- it.yml
```

Sembra tutto un pò confuso, man mano che andremo avanti sarà tutto più chiaro.


## Localizzare il titolo della pagina.
Mettiamo subito in pratica alcune delle idee sopra menzionate e estraiamo il titolo della pagina in un dizionario di localizzazione. Innanzitutto, Rails dispone di un file predefinito per il dizionario di localizzazione, ma in questo progetto non lo utilizziamo, quindi eliminiamolo.

```sh
rm config/locales/en.yml
```

Ogni pagina fornirà facoltativamente il proprio `titolo`(`tag title`) per la `SEO`, ma includeremo anche un valore predefinito. Per agevolare ciò, utilizzeremo l'`helper content_for`.

Inoltre, definiremo un nostro `helper` per formattare il titolo, come segue.
Apriamo il file:
`app/helpers/application_helper.rb`

```ruby
module ApplicationHelper
    def title
        return t("app_name") unless content_for?(:title)

        "#{content_for(:title)} | #{t("app_name")}"
    end
end
```
Scriviamo anche un test per questo helper.

```sh
touch test/helpers/application_helper_test.rb
```
Apriamo il file appena creato:
`test/helpers/application_helper_test.rb`

```ruby
require 'test_helper'
class ApplicationHelperTest < ActionView::TestCase
    test "formats page specific title" do
        content_for(:title) { "Page Title" }
        assert_equal "Page Title | #{I18n.t('app_name')}", title
    end

    test "returns app name when page title is missing" do
    assert_equal I18n.t('app_name'), title
    end
end
```

Il test fallirà poiché non abbiamo ancora definito la stringa localizzata. 

Nella sezione precedente, abbiamo discusso di una struttura delle cartelle per i dizionari di localizzazione basata su `modelli`` e `viste`. Tuttavia, il `titolo` predefinito della pagina non appartiene a un tale contesto, ma è globale per l'applicazione. Ecco perché la chiave di traduzione non è preceduta da un punto (.).

Questa stringa appartiene a un file per le stringhe globali. Creiamo questo file come segue:
```sh
mkdir config/locales/globals
touch config/locales/globals/en.yml
```
e inseriamo il seguente contenuto:

```ruby
en:
  app_name: Shopping Gioioso
```

Ora i test dovrebbero passare. Eseguiamo nuovamente il test, con il comando:

```sh
bin/rails test
```

Riavvia il server Rails in modo che prenda in considerazione il nuovo dizionario di localizzazione. Modifica il `layout` dell'applicazione per utilizzare questo `helper`.

Apriamo il file del `layout`, `app/views/layouts/application.html.erb` e lo modifichiamo come segue:

```ruby
<!DOCTYPE html>
<html>
  <head>
    <title><%= title%></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_include_tag "application", "data-turbo-track": "reload", defer: true %>
  </head>

  <body>
    <%= render "shared/flashes"%>
    <main>
      <%= yield %>
    </main>
  </body>
</html>

```
Adesso la nostra applicazione web  ha il suo  tag `title`.
Il risultato non può essere ancora visto poiché non abbiamo creato alcune viste o controller. Sarà il prossimo passo!

[Prossima lezione - Signup Form](/documentation/chapter3/3_sign_up_form.md)