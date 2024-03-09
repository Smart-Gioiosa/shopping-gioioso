## Tests, tests, tests

Abbiamo appena scritto un mucchio di codice abbastanza critico per gestire l'`autenticazione`, e non c'è neanche un singolo test che lo copra. Non è ideale! L'approccio per testare i files `concerns` è un po' una valutazione soggettiva, poiché sono sempre mescolati con una classe e non vengono utilizzati da soli. Idealmente scriveremmo `test` per verificare il comportamento di una classe che testerebbe anche il file `concern` nel pacchetto.

Ma cosa succede se il file `concern` aggiunge la stessa funzionalità a un gran numero di classi? Ad esempio, il file `concern` di `autenticazione`. Non è pragmatico testare ogni singola azione del controller per la logica di autenticazione. In questi casi, credo che il miglior approccio sia testare il file `concern` in modo isolato.


#### Strumenti di test per i `concerns` utilizzati dal controller

Il file `concern` per  l'`autenticazione` è utilizzabile solo all'interno di un controller. Avremo bisogno di uno strumento di prova per testarla in modo indipendente. Lo strumento di prova sarà composto da un `TestController` e un insieme di percorsi che vi puntano e sono disponibili solo quando si esegue la suite di test.

Creiamo una cartella `support/` nella directory `test/` e creiamo alcuni files per lo strumento di prova al suo interno.

```sh
mkdir test/support
touch test/support/test_controller.rb
touch test/support/routes_helper.rb
```

Il `TestController` non deve fare molto da solo. Sarà sottoclassato nei singoli test. Ogni azione renderà il nome del controller e dell'azione, che potrà quindi essere verificato nei casi di test.
Il file `test/support/test_controller.rb`  mostra l'implementazione di questa classe:

```ruby
class TestController < ActionController::Base
    def index; end
    def new; end
    def create; end
    def show; end
    def edit; end
    def update; end
    def destroy; end


    private

    def default_render
        render plain: "#{params[:controller]}##{params[:action]}"
    end
end
```
Successivamente, abbiamo bisogno di un modo per definire alcune `routes` specifiche per i test che puntino alle sottoclassi di `TestController` nei casi di test. Le `routes` di test saranno circoscritte a `/test` in modo da non entrare in conflitto con le `routes` esistenti. L'`helper` per definire queste `routes` è mostrato nel file `test/support/routes_helper.rb`:

```ruby
# Ensure you call `reload_routes!` in your test's `teardown`
# to erase all the routes drawn by your test case.
module RoutesHelpers
    def draw_test_routes(&block)
        # Don't clear routes when calling `Rails.application.routes.draw`
        Rails.application.routes.disable_clear_and_finalize = true

        Rails.application.routes.draw do
            scope "test" do
                instance_exec(&block)
            end
        end
    end

    def reload_routes!
        Rails.application.reload_routes!
    end
end
```
L'`helper` **draw_test_routes** prende un blocco di istruzioni che viene eseguito all'interno del contesto di `Rails.application.routes.draw`. In sostanza, sta facendo esattamente la stessa cosa di `config/routes.rb`, ma nel contesto della suite di test.

I file nella cartella `test/` in Rails non vengono caricati automaticamente, quindi è necessario richiederli ed includerli manualmente.

`test/test_helper.rb`

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Dir[Rails.root.join("test", "support", "**", "*.rb")].each {
  |f| require f
}

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end

  class ActionDispatch::IntegrationTest
    include RoutesHelpers
  end
  
end
```
Con l'infrastruttura di `test` in posizione, ora possiamo scrivere alcuni test per il `concern` `Authenticate`. Creiamo un file per essi

```sh
mkdir test/controllers/concerns
touch test/controllers/concerns/authenticate_test.rb
```
e scriviamo i test come mostrato nel file `test/controllers/concerns/authenticate_test.rb`

```ruby
require 'test_helper'

class AuthenticateTestsController < TestController
    include Authenticate
    
    skip_authentication only: [:new, :create]
    allow_unauthenticated only: :show

    def show
        render plain: "User: #{Current.user&.id&.to_s}"
    end
end

class AuthenticateTest < ActionDispatch::IntegrationTest
    
    setup do
        @user = users(:jerry)
        draw_test_routes do
            resource :authenticate_test,
            only: [:new, :create, :show, :edit]
        end
    end
    
    teardown do
        reload_routes!
    end

    test "request authenticated by cookie gets valid response" do
        @user.app_sessions.destroy_all
        log_in(@user)

        get edit_authenticate_test_path

        assert_response :ok
        assert_match /authenticate_tests#edit/, response.body
    end

    test "unauthenticated request renders login page" do
        get edit_authenticate_test_path

        assert_response :unauthorized
        assert_equal I18n.t("login_required"), flash[:notice]
        assert_select "form[action='#{login_path}']"
    end

    test "authentication is skipped for actions marked to do so" do
        get new_authenticate_test_path
        assert_response :ok
        assert_match /authenticate_tests#new/, response.body

        post authenticate_test_path
        assert_response :ok
        assert_match /authenticate_tests#create/, response.body
    end

    test "unauthenticated requests are allowed when marked" do
        get authenticate_test_path
        assert_response :ok
        assert_equal "User: ", response.body

        log_in(@user)
        get authenticate_test_path
        assert_response :ok
        assert_equal "User: #{@user.id}", response.body
    end

    private
    def log_in(user, password: "password")
        post login_path, params: {
            user: {
                email: user.email,
                password: password
            }
        }
    end

end
```

`AuthenticateTestsController` specifico per i test elimina qualsiasi funzionalità periferica e ci consente di concentrarci sui test del codice in `Authenticate`. Ora può essere testato proprio come qualsiasi altro controller! Eseguiamo la suite di test.

```sh
bin/rails test
```

**Yay, è verde!**  Tutti i test sono passati con successo!!!

C'è un'opportunità per un piccolo `refactoring` qui. Il metodo privato `log_in` è utilizzato al di fuori del contesto di questo caso di test. La maggior parte dei test dei controller avrà bisogno di un utente autenticato. Crea un nuovo file di supporto nella cartella `support/` e sposta questo metodo all'interno di esso.

```sh
touch test/support/authentication_helpers.rb
```
Apri il file appena creato.

*Un assistente generico per effettuare l'accesso durante i test.*
`test/support/authentication_helper.rb`
```ruby
def log_in(user, password: "password")
    post login_path, params: {
        user: {
            email: user.email,
            password: password
        }
    }
end 
```
Includi gli assistenti di autenticazione nell'assistente di test.

Apriamo il file:
`test/test_helper.rb`

```ruby
#...
class ActionDispatch::IntegrationTest
  include AuthenticationHelpers
  include RoutesHelpers
end
```

Ricorda di eliminare il metodo `log_in` dalla classe `AuthenticateTest` e poi esegui nuovamente l'insieme di test per assicurarti che nulla si sia rotto.

```sh
bin/rails test
```
Perfetto funziona tutto!

Questo nuovo assistente può essere utilizzato anche nel `SessionsControllerTest`.

*Refactor(Ottimizzazione) del file `SessionsControllerTest` utilizzando l'helper `login`*

Apri il file: `test/controllers/sessions_controller_test.rb` e sostituisci:

```ruby 
#...
post login_path, params: {
    user: {
        email: "jerry@example.com",
        password: "password"
        }
    }
#...
```

con:

```ruby
#...
test "user is logged in and redirected to home with correct credentials" do

    assert_difference("@user.app_sessions.count", 1) {
        log_in(@user)
    }
    assert_not_empty cookies[:app_session]
    assert_redirected_to root_path
  end
  #...
```

Esegui il test per verificare che funzioni tutto:
```sh
bin/rails test
```

Perfetto! Funziona tutto!!!

## Ottimizzazione del modello `User` attraverso `Concerns`

Ora che abbiamo un po' di esperienza nell'uso delle `concerns`, rifattorizziamo il modello `user` per pulirlo un po'. C'è parecchio codice relativo all'autenticazione che può essere estratto in una singola "model concern". In questo modo, sarà raggruppato in modo ordinato ma nascosto per evitare di appesantire il file principale del modello.

Le `single model concerns` sono annidate con il nome del modello per rendere chiaro che dovrebbero essere utilizzate solo all'interno di quel modello. Crea il file e procediamo con la rifattorizzazione.

```sh
mkdir app/models/user
touch app/models/user/authentication.rb
```

Taglia il seguente codice, dal modello `User` principale situato  in `app/models/user.rb`:

```ruby
#...
    has_secure_password
        validates :password, 
            presence: true, 
            length: {minimum: 8}

    has_many :app_sessions

    def self.create_app_session(email:, password:)
        return nil unless user = User.find_by(email: email.downcase)
        
        user.app_sessions.create if user.authenticate(password)
    end

    def authenticate_app_session(app_session_id, token)
        app_sessions.find(app_session_id).authenticate_token(token)
    rescue ActiveRecord::RecordNotFound
        nil
    end
#...
```
e incollale nella nuova "concern" come indicato di seguito:
```ruby
module User::Authentication
    extend ActiveSupport::Concern
    
    included do
        has_secure_password
        
        validates :password,
        presence: true,
        length: { minimum: 8 }
        
        has_many :app_sessions
    end

    class_methods do
        def create_app_session(email:, password:)
            return nil unless user = User.find_by(email: email.downcase)
            user.app_sessions.create if user.authenticate(password)
        end
    end

    def authenticate_app_session(app_session_id, token)
        app_sessions.find(app_session_id).authenticate_token(token)
    rescue ActiveRecord::RecordNotFound
        nil
    end

end
```

E, infine, questa "concern" deve essere inclusa nel modello principale: `app/models/user.rb`

```ruby
class User < ApplicationRecord
    include Authentication
    # ...
end
```
Se il set di test è ancora verde, l'intervento è riuscito con successo.
```sh
bin/rails test
```
Il test è passato!!!

C'è un altro piccolo intervento di refactoring che potremmo fare. I test per il codice in `User::Authentication` sono ancora situati insieme ai test per il resto del modello in `UserTest`. Non c'è assolutamente nulla di sbagliato in questo, ma preferisco abbinare la stessa struttura di `concern` nei casi di test. Crea un nuovo caso di test `User::AuthenticationTest` per spostare eventuali test relativi al codice in `User::Authentication`.

```sh
mkdir test/models/user
touch test/models/user/authentication_test.rb
```
Sposta i test pertinenti nel nuovo file: `test/models/user/authentication_test.rb`.
```ruby
require "test_helper"

class User::AuthenticationTest < ActiveSupport::TestCase
  test "password length must be between 8 and ActiveModel's maximum" do
    @user = User.new(
      name: "Jane",
      email: "janedoe@example.com",
      password: ""
    )
    assert_not @user.valid?

    @user.password = "password"
    assert @user.valid?

    max_length =
      ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED
    @user.password = "a" * (max_length + 1)
    assert_not @user.valid?
  end

  test "can create a session with email and correct password" do
    @app_session = User.create_app_session(
      email: "jerry@example.com",
      password: "password"
    )

    assert_not_nil @app_session
    assert_not_nil @app_session.token
  end

  test "cannot create a session with email and incorrect password" do
    @app_session = User.create_app_session(
      email: "jerry@example.com",
      password: "WRONG"
    )

    assert_nil @session
  end

  test "creating a session with non existent email returns nil" do
    @app_session = User.create_app_session(
      email: "whoami@example.com",
      password: "WRONG"
    )

    assert_nil @app_session
  end

  test "can authenticate with a valid session id and token" do
    @user = users(:jerry)
    @app_session = @user.app_sessions.create

    assert_equal @app_session,
      @user.authenticate_app_session(@app_session.id, @app_session.token)
  end

  test "trying to authenticate with a token that doesn't exist returns false" do
    @user = users(:jerry)

    assert_not @user.authenticate_app_session(50, "token")
  end
end
```
Ricorda di eliminare i test corrispondenti da 'test/models/user_test.rb' e quindi esegui nuovamente l'insieme di test.