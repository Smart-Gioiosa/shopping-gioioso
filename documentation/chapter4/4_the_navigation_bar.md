# La barra di navigazione

Addesso costruiamo la struttura portante della navigazione di Shopping Gioioso: la barra di navigazione. Avrà un aspetto diverso per gli utenti loggati e non loggati. 

*Utenti loggati*

![Navbar LoggedIn - Shopping Gioioso](/documentation/chapter4/images/navigation_bar_logged_in.png "Mockup navbar logged in - Shopping Gioioso ")


*Utenti non loggati*

![Navbar LoggedOut - Shopping Gioioso](/documentation/chapter4/images/navigation_bar_logged_out.png "Mockup navbar logged out - Shopping Gioioso ")

## La struttura HTML della navbar

Iniziamo compilando il markup per lo stato di disconnessione della barra di navigazione. Questo andrà nel file di `layout` dell'applicazione perché deve essere presente su ogni pagina. Metteremo l'HTML in una partial e la includeremo nel layout per mantenere il codice ben organizzato.

```sh
touch app/views/shared/_navbar.html.erb
```

Includi la barra di navigazione nel layout dell'applicazione: `app/views/layouts/application.html.erb`:

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
    <%= render "shared/navbar"%>
    <%= render "shared/flashes"%>
    <main>
      <%= yield %>
    </main>
  </body>
</html>
```

Aggiungi il markup per la barra di navigazione nello stato di disconnessione, come mostrato di seguito.

Apriamo il file: `app/views/shared/_navbar.html.erb`

```ruby
<nav class="navbar is-link">
    <div class="navbar-brand">
        <%= link_to root_path, class: "navbar-item" do %>
            <strong class="is-size-3">Shopping Gioioso</strong>
        <% end %>

        <a role="button"
            class="navbar-burger">
            <span></span>
            <span></span>
            <span></span>
        </a>
    </div>

    <navbar-menu class="navbar-menu">
        <div class="navbar-start">
            <%= link_to t(".create_ad"),
            "#",
            class: "navbar-item" %>
        </div>

        <div class="navbar-end">
            <%= tag.div class: "navbar-item" do %>
                <div class="buttons">
                    <%= link_to t(".sign_up"),
                        sign_up_path,
                        class: "button is-primary" %>
                    
                    <%= link_to t(".login"),
                        login_path,
                        class: "button is-light" %>
                </div>
            <% end %>
        </div>
    </navbar-menu>
</nav>

```

Bulma fornisce la maggior parte dei componenti di cui abbiamo bisogno per impostare una barra di navigazione, quindi non c'è nulla di particolare nel markup, solo un insieme di classi Bulma. È utile notare che Bulma ha un elemento del menu burger per i dispositivi mobili che viene impostato utilizzando la classe `navbar-burger`. I tre tag `<span>` vuoti sono per le tre linee dell'icona del burger.

Aggiorna la homepage nel tuo browser e vedrai la nuova e brillante barra di navigazione come mostrato di seguito:

![Navbar - Shopping Gioioso](/documentation/chapter4/images/shopping-gioioso-navbar.png "Navbar - Shopping Gioioso ")

E se passi il tuo browser alla modalità responsive e riduci la larghezza, vedrai il menu a hamburger.

![Navbar Mobile- Shopping Gioioso](/documentation/chapter4/images/shopping-gioioso-navbar-mobile.png "Navbar mobile- Shopping Gioioso ")

Il menu a `hamburger` non funziona perché richiede alcuna logica JavaScript. Il framework css `Bulma` non include alcun JavaScript, quindi scriveremo un controller Stimulus nella prossima sezione per rendere il menu operativo.

Un utente loggato dovrebbe vedere un collegamento a `Messaggi` e un menu a discesa del profilo invece dei pulsanti `Sign Up` e `Login`. L'`helper logged_in?` nel `concern Authenticate` può essere utilizzato per ottenere questo risultato. 

Apri il partial situato in  `app/views/shared/_navbar.html.erb`e modificalo come segue:

```ruby
<nav class="navbar is-link">
    <div class="navbar-brand">
        <%= link_to root_path, class: "navbar-item" do %>
            <strong class="is-size-3">Shopping Gioioso</strong>
        <% end %>

        <a role="button"
            class="navbar-burger">
            <span></span>
            <span></span>
            <span></span>
        </a>
    </div>

    <navbar-menu class="navbar-menu">
        <div class="navbar-start">
            <%= link_to t(".create_ad"),
            "#",
            class: "navbar-item" %>
            <%= link_to t(".messages"),
                "#",
                class: "navbar-item" if logged_in? %>
        </div>

        <div class="navbar-end">
            <%= tag.div \
                class: "navbar-item has-dropdown
                is-hoverable mr-4" do %>

                <%= link_to Current.user.name,
                    "#",
                    class: "navbar-link" %>

                <div class="navbar-dropdown is-right">
                    <%= link_to t(".profile"),
                        "#",
                        class: "navbar-item" %>

                    <%= link_to t(".my_ads"),
                        "#",
                        class: "navbar-item" %>

                    <%= link_to t(".saved_ads"),
                        "#",
                        class: "navbar-item" %>
                
                        <hr class="navbar-divider">

                    <%= link_to t(".logout"),
                        "#",
                        class: "navbar-item" %>
                </div>
            <% end if logged_in? %>


            <%= tag.div class: "navbar-item" do %>
                <div class="buttons">
                    <%= link_to t(".sign_up"),
                        sign_up_path,
                        class: "button is-primary" %>
                    
                    <%= link_to t(".login"),
                        login_path,
                        class: "button is-light" %>
                </div>
            <% end unless logged_in? %>
        </div>
    </navbar-menu>
</nav>
```
Dovrebbe funzionare! La maggior parte dei collegamenti nella barra di navigazione non porta da nessuna parte poiché quei controller e le viste non sono ancora stati creati. Se non hai effettuato l'accesso, fallo e vedrai la barra di navigazione nel suo stato di accesso. Abbiamo aggiunto un mucchio di nuove stringhe localizzate nell'HTML della barra di navigazione. 
Crea un nuovo dizionario di locale per loro e compilalo come segue:
```sh
mkdir config/locales/views/shared
mkdir config/locales/views/shared/navbar
touch config/locales/views/shared/navbar/en.yml
touch config/locales/views/shared/navbar/it.yml
```

*Aggiungi le stringhe localizzate*
`config/locales/views/shared/navbar/en.yml`
```ruby
en:
    shared:
        navbar:
            create_ad: Create Ad
            messages: Messages
            sign_up: Sign Up
            login: Login
            profile: Profile
            my_ads: My Ads
            saved_ads: Saved Ads
            logout: Log out
```
`config/locales/views/shared/navbar/it.yml`

```ruby
it:
    shared:
        navbar:
            create_ad: Crea Ad
            messages: Messaggi
            sign_up: Registrati
            login: Accedi
            profile: Profilo
            my_ads: I miei Ads
            saved_ads: Salva Ads
            logout: Esci
```

Riavvia il server Rails per incorporare il nuovo dizionario locale e assicurarti che le stringhe localizzate vengano renderizzate come previsto.

## Il nostro primo controller Stimulus

Ora diamo vita al menu ad hamburger nella barra di navigazione. Secondo la documentazione di `Bulma`, è necessario aggiungere una classe CSS `is-active` agli elementi `navbar-burger` e `navbar-menu` per aprire il menu ad `hamburger`. Creeremo un `controller Stimulus` per questo, lo collegheremo alla barra di navigazione e designiamo i due elementi sopra menzionati come `target`. Quindi, utilizzando un'azione, la classe `is-active` può essere attivata o disattivata. Rails include di default un esempio di controller Stimulus chiamato `hello_controller.js`. È inutile, quindi vai avanti e cancellalo.

```sh
rm app/javascript/controllers/hello_controller.js
```

La `stimulus-rails` (incluso di default) dispone di un utile generatore per creare nuovi controller `Stimulus`. Utilizzandolo, crea un controller per la barra di navigazione.

```sh
bin/rails g stimulus navbar
```
Il controller verrà creato nella cartella `app/javascript/controllers/`. Avrà un aspetto simile a quanto mostrato di seguito:

*Il controller per la barra di navigazione generato.*
`app/javascript/controllers/navbar_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="navbar"
export default class extends Controller {
  connect() {
  }
}

```

Il metodo `connect` viene chiamato quando il controller viene allegato al `DOM`. È utile per eseguire qualsiasi configurazione necessaria, ma in questo caso non è necessario. Il generatore ha anche registrato questo nuovo controller nell'applicazione Stimulus. Puoi vedere ciò in:

*Il nuovo controller è registrato con Stimulus.*
`app/javascript/controllers/index.js`

```javascript

// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import NavbarController from "./navbar_controller"
application.register("navbar", NavbarController)

```

L'implementazione del controller stimulus `navbar` è mostrata di seguito:

`app/javascript/controllers/navbar_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"
    export default class extends Controller {
    static targets = [ "burger", "menu" ]
    
    toggle() {
        this.burgerTarget.classList.toggle("is-active")
        this.menuTarget.classList.toggle("is-active")
    }
}
```
Il menu ad hamburger è collegato al metodo di `toggle` utilizzando un'azione, che cambierà la classe necessaria per aprirlo e chiuderlo. L'ultimo passo è aggiungere gli attributi HTML per collegare questo controller al `DOM`.

*HTML, incontra Stimulus.*
`app/views/shared/_navbar.html.erb`
```ruby
<nav class="navbar is-link" data-controller="navbar">
    <div class="navbar-brand">
        <%= link_to root_path, class: "navbar-item" do %>
            <strong class="is-size-3">Shopping Gioioso</strong>
        <% end %>

        <a role="button"
            class="navbar-burger"
            data-navbar-target="burger"
            data-action="navbar#toggle">
            <span></span>
            <span></span>
            <span></span>
        </a>
    </div>

    <navbar-menu class="navbar-menu" data-navbar-target="menu">
        <div class="navbar-start">
            <%= link_to t(".create_ad"),
            "#",
            class: "navbar-item" %>
            <%= link_to t(".messages"),
                "#",
                class: "navbar-item" if logged_in? %>
        </div>

        <div class="navbar-end">
            <%= tag.div \
                class: "navbar-item has-dropdown
                is-hoverable mr-4" do %>

                <%= link_to Current.user.name,
                    "#",
                    class: "navbar-link" %>

                <div class="navbar-dropdown is-right">
                    <%= link_to t(".profile"),
                        "#",
                        class: "navbar-item" %>

                    <%= link_to t(".my_ads"),
                        "#",
                        class: "navbar-item" %>

                    <%= link_to t(".saved_ads"),
                        "#",
                        class: "navbar-item" %>
                
                        <hr class="navbar-divider">

                    <%= link_to t(".logout"),
                        "#",
                        class: "navbar-item" %>
                </div>
            <% end if logged_in? %>


            <%= tag.div class: "navbar-item" do %>
                <div class="buttons">
                    <%= link_to t(".sign_up"),
                        sign_up_path,
                        class: "button is-primary" %>
                    
                    <%= link_to t(".login"),
                        login_path,
                        class: "button is-light" %>
                </div>
            <% end unless logged_in? %>
        </div>
    </navbar-menu>
</nav>
```

Dovrebbe funzionare. Aggiorna la pagina, passa il tuo browser in modalità responsiva e vedrai il menu ad hamburger in azione!
Se il menu non funziona ancora, interrompi il tuo server Rails e esegui `bin/rails assets:clobber`. Quindi avvia nuovamente il tuo server.

Committa il tuo codice prima di procedere.