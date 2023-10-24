### Form di registrazione

Siamo ora pronti a scrivere del codice dell'interfaccia utente da poter vedere i frutti del nostro lavoro. Come precedentemente menzionato utilizzeremo per il nostro css [Bulma](https://bulma.io/). Bulma è un frmework class-based molto intuitivo.


#### Configurazione delle rotte(`routes`), dei controller e delle viste.

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

#### Sviluppo del form di registrazione.

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


#### Rendere i messaggi flash

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