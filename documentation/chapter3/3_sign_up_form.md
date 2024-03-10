# Form di registrazione

Siamo ora pronti a scrivere del codice dell'interfaccia utente da poter vedere i frutti del nostro lavoro. Come precedentemente menzionato utilizzeremo per il nostro css [Bulma](https://bulma.io/). Bulma è un frmework class-based molto intuitivo.


## Configurazione delle rotte(`routes`), dei controller e delle viste.

La prima cosa di cui abbiamo bisogno è un `UsersController` insieme alle azioni per mostrare il modulo di registrazione e gestire la sottomissione(`l'invio del modulo`).
 La homepage di `Shopping Gioioso` sarà un feed di annunci di prodotti. Entreremo nei dettagli in seguito, ma creiamo anche un `FeedController`. L'utente verrà reindirizzato al feed dopo essersi registrato. 
 
 Eseguiamo i comandi seguenti per creare i `controller`, le `azioni` e le `viste`:

 ```sh
 bin/rails g controller Users new create
 bin/rails g controller Feed show
 ```

Il generatore creerà un file `app/views/users/create`.html.erb che non è necessario.

```sh
rm app/views/users/create.html.erb
```

Successivamente, è necessario configurare le rotte per queste azioni del controller. 
Il percorso radice(`root`) sarà l'azione `show` nel `FeedController`. Per il modulo di registrazione, è utile avere un percorso amichevole per l'utente, quindi lo serviremo `/sign_up` anziché il convenzionale `/users/new`.
Apriamo il file `routes.rb` e apportiamo le seguente modifiche:

`config/routes.rb`

```ruby
Rails.application.routes.draw do
    root "feed#show"

    get "sign_up", to: "users#new"
    post "sign_up", to: "users#create"

end
```

Se visiti [http://localhost:3000/](http://localhost:3000/) e [http://localhost:3000/sign_up](http://localhost:3000/sign_up) nel tuo browser web, dovresti vedere un po' di testo con la posizione del file di visualizzazione. 

## Sviluppo del form di registrazione.

![Mockup form di registrazione per Shopping Gioioso](/documentation/chapter3/images/SignUp-ShoppingGioioso.png "Mockup form di registrazione")

In base al mockup, possiamo scrivere il codice per visualizzare il form di registrazione. Apriamo il file `app/views/users/new.html.erb`

```ruby
<% content_for :title, t(".title") %>
<layout-columns class="columns is-centered">
    <layout-column class="column box is-5 mt-6 p-5 m-4">
        <h1 class="title has-text-centered">
            <%= t(".title") %>
        </h1>

        <%= form_with( model: @user, url: sign_up_path, class: "is-flex is-flex-direction-column") do |form| %>

            <div class="block">
                <%= form.label :name, class: "label"%>
                <%= form.text_field :name, class: "input" %>
            </div>

            <div class="block">
                <%= form.label :email, class: "label" %>
                <%= form.email_field :email, class: "input" %>
            </div>
        
            <div class="block">
                <%= form.label :password, class: "label" %>
                <%= form.password_field :password, class: "input" %>
            </div>
        
            <%= form.submit t(".sign_up"), class: "button is-primary is-large is-align-self-flex-end mb-3 mt-3" %>
        
        <% end %>

    </layout-column>
</layout-columns>
```

Questo codice non funzionerà in quanto la variabile di istanza `@user` utilizzata per costruire il modulo non è stata definita nel controller. Stiamo inoltre utilizzando un paio di stringhe localizzate che non esistono nel dizionario delle localizzazioni.

Adesso spostiamoci nel file `app/controllers/users_controller.rb` e implementiamo le `azioni`, `new` e `create`, come di seguito:

```ruby
class UsersController < ApplicationController
  def new
     @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @organization = Organization.create(members: [@user])
      redirect_to root_path,
        status: :see_other,
        flash: {success: t(".welcome", name: @user.name)}
    else
        render :new, status: :unprocessable_entity
    end
  end

  private
  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
end
```

L'azione `new` inizializza una nuova istanza di `User` per costruire il form di registrazione. L'azione `create` crea un nuovo utente insieme a un'`organizzazione` associata.

Adesso, inseriamo le stringhe localizzate utilizzate nel modulo di registrazione. Come discusso nel [capitolo dell'internazionalizzazione](/documentation/chapter3/rails_and_18n.md) creaiamo i files del dizionario delle localizzazioni per il modello `User` e il controller `UsersController`:

```sh
mkdir config/locales/models
mkdir config/locales/views
mkdir config/locales/models/user
mkdir config/locales/views/users

touch config/locales/models/user/en.yml
touch config/locales/models/user/it.yml

touch config/locales/views/users/en.yml
touch config/locales/views/users/it.yml
```

Quindi modifichiamo il file `config/locales/views/users/en.yml` e inseriamo le seguenti stringhe localizzate:

```ruby
en:
  users:
    new:
      title: Sign up for Shopping Gioioso
      sign_up: Sign up!
    create:
      welcome: "Welcome to Shopping Gioioso, %{name}"
```

Per la lingua `italiana`, modifichiamo il file `config/locales/views/users/it.yml` 

```ruby
it:
  users:
    new:
      title: Iscriviti su Shopping Gioioso
      sign_up: Iscriviti!
    create:
      welcome: "Benvenuto su Shopping Gioioso, %{name}"
```

Inoltre impostiamo i files per localizzare i modelli:

Per la lingua `inglese`:
`config/locales/models/user/en.yml`

```ruby
en:

```

e per la lingua `italiana`:
`config/locales/models/user/it.yml`

```ruby
it: 

```
Abbiamo inserito le due stringhe che stiamo utilizzando nel modulo di registrazione, così come il messaggio di avviso mostrato dopo una registrazione riuscita. Quest'ultimo caso dimostra anche come interpolare valori nelle stringhe localizzate.

Riavvia il server Rails in modo che prenda in considerazione i dizionari delle localizzazioni appena creati. Successivamente, visita [http://localhost:3000/sign_up](http://localhost:3000/sign_up) e vedrai il nuovissimo modulo di registrazione, come mostrato nell'immagine seguente:


![Form di registrazione per Shopping Gioioso](/documentation/chapter3/images/signup_form.png "Form di registrazione")

Adesso procediamo alla compilazione del form  con dati validi e sarermo reindirizzati al percorso radice(`home page`). 
Ma notiamo che manca ilil messaggio di benvenuto. L'abbiamo memorizzato nel flash, ma deve ancora essere reso nella UI.


## Rendere i messaggi flash

Il meccanismo `flash` di Rails viene utilizzato per visualizzare avvisi in tutto l'applicazione, quindi appartiene al file layout  `application.html.erb`:

`app/views/layouts/application.html.erb`

```ruby
<!DOCTYPE html>
<html>
    <%# ... %>
    <body>
        <%= render "shared/flashes" %>
        <main>
        <%= yield %>
        </main>
    </body>
</html>
```

Adesso, creiamo e compiliamo il `partial` per i messaggi flash.

```sh
mkdir app/views/shared

touch app/views/shared/_flashes.html.erb
```

`app/views/shared/_flashes.html.erb`

```ruby
<div class="container is-fluid" data-turbo-temporary>
    <% flash.each do |level, message| %>
        <%= tag.div \
            class: "notification is-#{level} is-light
            has-text-centered mt-4" do %>
            <%= message %>
        <% end %>
    <% end %>
</div>
```

Il codice nel file `app/views/shared/_flashes.html.erb` mostra come avviene il rendering  dei messaggi `flash`. `data-turbo-temporary` è specificato sul contenitore per evitare che `Turbo` memorizzi questo elemento durante la navigazione. Senza questo attributo, gli utenti vedranno l'avviso per una frazione di secondo prima che scompaia se tornano indietro a una pagina con un avviso dopo essersi allontanati. Questo perché Turbo mantiene una cache locale delle pagine visitate. Gli avvisi dovrebbero essere effimeri, quindi è una buona idea escluderli dalla cache.

Ora, se torniamo al form di registrazione e lo inviamo con dati validi, vedremo un avviso come rappresentato nell'immagine seguente:

![Messaggi flash Shopping Gioioso](/documentation/chapter3/images/messages_flash_green.png "Messaggi flash con dati validi")

Il form funziona bene con dati validi, ma cosa succede con dati non validi?

## Rendering degli errori di input del form.

Ogni applicazione web dovrebbe essere progettata per gestire input imprevisti e non validi da parte dell'utente. 

Iscriversi a Shopping Gioioso con una `email` duplicata o con una `password` più corta di 8 caratteri dovrebbe comportare un errore.

Ma al momento, non succede nulla. O meglio, quasi nulla. Se inviamo il form con una password troppo corta e poi visualizziamo il sorgente HTML, possiamo vedere il codice seguente quando si ispeziona il campo password:

```ruby
<div class="block">
    <div class="field_with_errors">
        <label class="label" for="user_password">Password</label>
    </div>

    <div class="field_with_errors">
        <input class="input" type="password" name="user[password]" id="user_password">
    </div>
</div>
```

Rails ha avvolto i campi che contengono errori in un `<div>` con la classe `field_with_errors`. Tuttavia, questa modalità di rendering degli errori non funziona per noi perché `Bulma` non ha alcun concetto di `field_with_errors`. Utilizza una classe chiamata `is-danger` per indicare gli errori, quindi dobbiamo modificare il comportamento predefinito per gli errori del modulo.

`ActionView::Base` ha un campo `field_error_proc` che può essere impostato per personalizzare l'output dei campi dei form che contengono errori. Il posto migliore per farlo è in un inizializzatore che va nella cartella `config/initializers/`. Ogni file in questa cartella viene eseguito quando Rails si avvia. Crea un nuovo file in quella cartella:

```sh
touch config/initializers/form_errors.rb
```

Compiliamo il file `config/initializers/form_errors.rb` appena creato con il seguente contenuto:

```ruby
ActionView::Base.field_error_proc = -> (html_tag, instance) {
    unless html_tag =~ /^<label/
        html = Nokogiri::HTML::DocumentFragment.parse(html_tag)
        html.children.add_class("is-danger")

        error_message_markup = <<~HTML
            <p class='help is-danger'>
                #{sanitize(instance.error_message.to_sentence)}
            </p>
        HTML

        "#{html.to_s}#{error_message_markup}".html_safe
    else
        html_tag
    end
}
```

Esaminiamo il codice presente nel file `config/initializers/form_errors.rb` riga per riga. Il `field_error_proc` deve essere una `lambda` o `Proc`. Stiamo utilizzando una lambda, che è una funzione anonima che può essere assegnata a una variabile.

Questo sarà chiamato dal form builder (di default, un'istanza di ActionView::Helpers::FormBuilder) quando renderizza un campo contenente un errore. Vengono passati due argomenti. 
Il primo è l'etichetta HTML completa per il campo che contiene un errore. Ad esempio, se il campo della password ha un errore, la stringa seguente verrebbe passata come html_tag:

```sh
"<input class='input' type='password' name='user[password]' id='user_password'>"
```

Il secondo argomento è un'istanza del campo dal `FormBuilder` per il modulo, che è una sottoclasse di `ActionView::Helpers::Tags::Base`. Per un campo `password`, sarà un'istanza di `ActionView::Helpers::Tags::PasswordField`.

Conoscendo le informazioni che vengono passate alla funzione lambda, possiamo procedere con l'implementazione. 
Questa funzione lambda viene chiamata per l'elemento <label> dell'attributo problematico, così come per l'elemento <input>. L'errore deve essere mostrato solo sull'elemento <input>, quindi utilizzando una semplice verifica con espressioni regolari, l'elemento <label> viene ignorato.

Per tutti gli altri tag, è necessario aggiungere la classe `is-danger` in modo che Bulma renda l'elemento in uno stato di errore. Utilizzando una libreria chiamata Nokogiri, che è inclusa in Rails, analizziamo e manipoliamo l'HTML.

```ruby
html = Nokogiri::HTML::DocumentFragment.parse(html_tag)
html.children.add_class("is-danger")
```

Abbiamo anche bisogno di visualizzare il messaggio di errore. Questo è disponibile nell'istanza passata alla funzione lambda, quindi avvolgendolo in un tag <p>, lo aggiungiamo all'elemento <input>.

```ruby

error_message_markup = <<~HTML
    <p class='help is-danger'>
        #{sanitize(instance.error_message.to_sentence)}
    </p>
HTML

"#{html.to_s}#{error_message_markup}".html_safe

```

Viene chiamato `html_safe` sulla stringa finale prima di restituirla, in modo che Rails non esegua l'escape dell'HTML e lo visualizzi a schermo come codice. Questa è una funzionalità di sicurezza evita che l'input dannoso degli utenti possa causare problemi nell'applicazione. Ecco perché effettuiamo il `sanitize` del messaggio di errore prima di utilizzarlo. Assicuriamoci di chiamare `html_safe` solo su stringhe di cui siamo certi che siano sicure e non contengano input utente che non sia passato al metodo ``sanitize.

Adesso riavviamo il server `Rails` in modo che questo inizializzatore venga eseguito. Successivamente, inviamo nuovamente il modulo di registrazione con dati non validi e vedremo gli errori essere visualizzati a schermo.

![Sign Up - Errors - Shopping Gioioso](/documentation/chapter3/images/sign_up_with_errors.png "Visualizzare i messagi di errore nel form di registrazione")

## Personalizzare i messaggi di errore di Active Record
I messaggi di errore visualizzati nel form di registrazione provengono da `Active Record`. Essi vengono generati quando le validazioni del modello non vengono soddisfatte. Di conseguenza, essi possono essere `personalizzati` o `localizzati` nello stesso modo dei nomi del modello o degli attributi di `Active Record`.

Il modo più semplice per determinare la chiave per una qualsiasi stringa data è utilizzare una gemma chiamata `i18n-debug`. Essa registra la chiave di localizzazione per ogni stringa visualizzata in una vista sulla console.

Aggiungiamo questa gemma al gruppo di sviluppo nel tuo `Gemfile` in quanto non è necessaria al di fuori dell'ambiente locale.

`Gemfile`

```ruby
# ...
group :development do
# ...
    gem "i18n-debug"
end
```
Poi esguiamo:
```sh
bundle install
```

Riavviamo il server di Rails e inviamo nuovamente il form con una password troppo corta. Nei log del server sulla  console, vedremo le chiavi di localizzazione di ogni stringa visualizzata nella vista.

Esaminando attentamente queste chiavi, vedremo:
`en.activerecord.errors.models.user.attributes.password.too_short``
Questa è la chiave per localizzare il messaggio di errore per una password troppo corta.
Andiamo a modificaere il file: `config/locales/models/user/en.yml`

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
    errors:
      models:
        user:
          attributes:
            password:
              too_short: must be at least 8 characters long
```

Ancora una volta, inviamo il form con una password troppo corta e vedremo il nuovo messaggio di errore.

![Sign Up - Messaggio di errore personalizzato - Shopping Gioioso](/documentation/chapter3/images/custom_message_error.png "Visualizzare i messagi di errore peronalizzati nel form di registrazione")

## Test del controller

Con il flusso di registrazione attivo, è una buona idea avvolgerlo in alcuni test del controller. Questi test si concentrano su un singolo controller e fanno richieste HTTP a un percorso e verificano le risposte.

Per il controller `UsersController`, testeremo che il form di registrazione possa essere inviato con successo e mostri errori per dati non validi. 
Il generatore di Rails avrà generato un paio di test di esempio. Cancelliamo il loro contenuto e sostituiamo con quanto mostrato di seguito:

`test/controller/users_controller_test.rb`

```ruby
equire "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "redirects to feed after successful sign up" do
    get sign_up_path
    assert_response :ok
    
    assert_difference [ "User.count", "Organization.count" ], 1 do
      post sign_up_path, params: {
        user: {
          name: "John",
          email: "johndoe@example.com",
          password: "password"
        }
      }
    end

    
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".notification.is-success", text: I18n.t("users.create.welcome", name: "John")

  end

  test "renders errors if input data is invalid" do
    get sign_up_path
    assert_response :ok
  
    assert_no_difference [ "User.count", "Organization.count" ] do
      post sign_up_path, params: {
        user: {
          name: "John",
          email: "johndoe@example.com",
          password: "pass"
        }
      }
    end
    
    
    assert_response :unprocessable_entity
    assert_select "p.is-danger",
    text: I18n.t("activerecord.errors.models.user.attributes.password.too_short")
  
  end
end
```
Adesso modifichiamo anche il file `test/controller/feed_controller_test.rb`

```ruby
require "test_helper"

class FeedControllerTest < ActionDispatch::IntegrationTest
 
end

```

I due casi di test nel file `test/controller/users_controller_test.rb` simulano le richieste `HTTP` effettuate quando un utente invia il form di registrazione, prima con dati validi e poi con una password che non soddisfa i requisiti.

Possiamo anche notare come il `test asserisce` il testo sulla pagina utilizzando la `chiave di localizzazione`. Se il testo rivolto all'utente cambia, i test non si romperanno in quanto stanno effettivamente testando una variabile.

L'elenco completo delle azioni di test disponibili nei test del controller è disponibile nella documentazione di Rails: [https://api.rubyonrails.org/classes/ActionDispatch/Integration/RequestHelpers.html](https://api.rubyonrails.org/classes/ActionDispatch/Integration/RequestHelpers.html).

I metodi di asserzione specifici per i test del controller si trovano nella loro repository dedicata chiamata `rails-dom-testing`. La documentazione è disponibile qui: [https://www.rubydoc.info/gems/rails-dom-testing/](https://www.rubydoc.info/gems/rails-dom-testing/).

[Prossima lezione](/documentation/chapter4/1_cookie_based_authentication.md)