# Logging out
Gli utenti possono ora effettuare l'accesso a Shopping Gioioso e navigare utilizzando la barra di navigazione, ma non possono effettuare il logout! Una volta effettuato l'accesso, sono bloccati per sempre. C'è un collegamento `Logout` nel menu a discesa della barra di navigazione, ma al momento è solo un segnaposto. Colleghiamolo.

Per effettuare il logout di un utente, è necessario distruggere `Current.app_session`. Pertanto, il verbo `HTTP` in modo idiomatico corretto è `DELETE`. Definisci la route come mostrato di seguito:

`config/routes`
```ruby
Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  root "feed#show"

  get "sign_up", to: "users#new"
  post "sign_up", to: "users#create"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

end
```
Prima di scrivere il codice dell'applicazione, è utile scrivere un test che fallisca. Abbiamo un metodo di aiuto per effettuare l'accesso, quindi collegiamolo con un metodo di aiuto per effettuare il logout.

`test/support/authentication_helpers.rb`

```ruby
module AuthenticationHelpers
    def log_in(user, password: "password")
        post login_path, params: {
            user: {
                email: user.email,
                password: password
            }
        }
    end

    def log_out
        delete logout_path
    end

end
```
Successivamente, possiamo scrivere un test per garantire che il conteggio delle app_sessions di un utente diminuisca di 1 durante il logout.
`test/controllers/sessions_controller_test.rb`
```ruby
require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  
  setup do
    @user = users(:jerry)
  end

  test "user is logged in and redirected to home with correct credentials" do

    assert_difference("@user.app_sessions.count", 1) {
      log_in(@user)
      }
      
    assert_not_empty cookies[:app_session]
    assert_redirected_to root_path
  end

  test "error is rendered for login with incorrect credentials" do

    post login_path, params: {
      user: {
        email: "wrong@example.com",
        password: "password"
      }
    }
    assert_select ".notification",  I18n.t("sessions.create.incorrect_details")

  end

  test "logging out redirects to the root url and deletes the session" do
    log_in(@user)
    assert_difference("@user.app_sessions.count", -1) { log_out }
    assert_redirected_to root_path

  end

end

```

La logica del logout appartiene al `concern` `Authenticate`, accanto alla logica di login.

`app/controllers/concerns/authenticate.rb`

```ruby
module Authenticate
    extend ActiveSupport::Concern

    #...
    protected

    def logged_in?
        Current.user.present?
    end

    def log_in(app_session)
        cookies.encrypted.permanent[:app_session] = {value: app_session.to_h}
    end

    def log_out
        Current.app_session&.destroy
    end
    #...
end

```
Successivamente, definisci l'azione destroy nel SessionsController.

*L'azione destroy invoca il metodo log_out*
`app/controllers/sessions_controller.rb`

```ruby
class SessionsController < ApplicationController
    skip_authentication only: [:new, :create]
    def new
    end

    def create
        
        @app_session = User.create_app_session(email: login_params[:email],password: login_params[:password])
        if @app_session
            log_in(@app_session)
            flash[:success] = t(".success")
            redirect_to root_path, status: :see_other
        else
            flash.now[:danger] = t(".incorrect_details")
            render :new, status: :unprocessable_entity
        end

    end

    def destroy
        log_out
        flash[:success] = t(".success")
        redirect_to root_path, status: :see_other
    end

    private
    def login_params
        @login_params ||=params.require(:user).permit(:email, :password)
    end

end

```

Aggiungi la nuova stringa localizzata.

*Aggiungi il messaggio di successo alla visualizzazione del dizionario locale.*

`config/locales/views/sessions/en.yml`
```ruby
en: 
  sessions:
    new:
      title: Log In
      submit: Login
    create:
      success: You're logged in!
      incorrect_details: The email or password was incorrect. Please try again.
    destroy:
      success: You've logged out successfully!
```
`config/locales/views/sessions/it.yml`

```ruby
it: 
  sessions:
    new:
      title: Log In
      submit: Login
    create:
      success: Sei connesso!
      incorrect_details: L'indirizzo email o la password non sono corretti. Per favore, riprova.
    destroy:
      success: Hai effettuato il logout con successo!
```


Ora esegui la suite di test e dovrebbe essere verde!

Il test può (e dovrebbe) essere migliorato per verificare il messaggio flash dopo che un utente ha effettuato il logout.
`test/controllers/sessions_controller_test.rb`

```ruby
require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  
  setup do
    @user = users(:jerry)
  end

  test "user is logged in and redirected to home with correct credentials" do

    assert_difference("@user.app_sessions.count", 1) {
      log_in(@user)
      }
      
    assert_not_empty cookies[:app_session]
    assert_redirected_to root_path
  end

  test "error is rendered for login with incorrect credentials" do

    post login_path, params: {
      user: {
        email: "wrong@example.com",
        password: "password"
      }
    }
    assert_select ".notification",  I18n.t("sessions.create.incorrect_details")

  end

  test "logging out redirects to the root url and deletes the session" do
    log_in(@user)
    assert_difference("@user.app_sessions.count", -1) { log_out }
    assert_redirected_to root_path

    follow_redirect!
    assert_select ".notification", I18n.t("sessions.destroy.success")
    
  end

end
```

L'ultimo passo è collegare il link di logout nella barra di navigazione. Nativamente, i tag `<a>` possono eseguire solo richieste `GET`, ma Turbo supporta un attributo HTML `data-turbomethod` tramite il quale il link può essere impostato per eseguire richieste con altri verbi `HTTP`. L'implementazione è mostrata ndi seguito:
`app/views/shared/_navbar.html.erb`

```ruby
<%#...%>
    <%= link_to t(".logout"),
        logout_path,
        class: "navbar-item",
        data: { turbo_method: :delete } %>
<%#...%>
```

Prova questo nel tuo browser e dovrebbe funzionare! Noterai anche lo stato della barra di navigazione cambiare una volta che effettui il logout.

