#### Logging in

Il controller responsabile di tutte le operazioni di accesso sarà il `SessionsController`, quindi creiamo quello.

```sh
bin/rails g controller sessions
```

L'azione `new` renderà la pagina di accesso(**Log In**). `/sessions/new ` non sembra un percorso URL molto accattivante, quindi definiamo un percorso `/login` per instradare verso questa azione.

Aggiungiamo il percorso nel file di routes `config/routes.rb`

```ruby
Rails.application.routes.draw do
  root "feed#show"

  get "sign_up", to: "users#new"
  post "sign_up", to: "users#create"

  get "login", to: "sessions#new"
end
```

Successivamente, definiamo l'azione `new`  e creiamo il file di visualizzazione ad essa associato.

`app/controllers/sessions_controller.rb`

```ruby
class SessionsController < ApplicationController
    def new
    end
end
```
Utiliziamo il comando `touch` per creare il file `new.html.erb` per visualizzare la pagina di login:

```sh
touch app/views/sessions/new.html.erb
```

Adesso coostruiamo il form di login, come l'immagine seguente:

![Log In - Shopping Gioioso](/documentation/chapter4/images/Login-ShoppingGioioso.png "Mockup della pagina di Login - Shopping Gioioso ")

Non ci resta che inserire il codice nel file `app/views/sessions/new.html.erb` per creare la nostra pagina di autenticazione:

```ruby
<layout-columns class="columns is-centered">
    <layout-column class="column box is-5 mt-6 p-5 m-4">
        <h1 class="title has-text-centered">
            <%= t("t.title")%>
        </h1>

        <%= form_with(url: login_path, scope: :user, class: "is-flex is-flex-direction-column") do |form|%>
            <div class="block">
                <%= form.label :email, class: "label"%>
                <%= form.email_field :email, class: "input"%>
            </div>

            <div class="block">
                <%= form.label :password, class: "label"%>
                <%= form.password_field :password, class: "input"%>
            </div>
            
            <%= form.submit t(".submit"), class: "button is-primary is-large is-align-self-flex-end mb-3 mt-3"%>

        <%end%>

    </layout-column>
</layout-columns>
```

Andiamo nella pagina http://localhost:3000/login del browser per visualizzare il modulo di accesso. Mancano alcune traduzioni, come mostra la figura seguente:

![Log In - Translation missing - Shopping Gioioso](/documentation/chapter4/images/translation-missing-shopping-gioioso.png "Translation missing - Shopping Gioioso ")

Le stringhe per le viste delle sessioni dovrebbero essere collocate nel proprio file di dizionario di locale.

```sh
mkdir config/locales/views/sessions

touch config/locales/views/sessions/en.yml

touch config/locales/views/sessions/it.yml
```

Aggiungiamo le nuove stringhe localizzate, per la lingua inglese.

`config/locales/views/sessions/en.yml`
```ruby
en: 
  sessions:
    new:
      title: Log In
      submit: Log In
```
E per la lingua italiana
`config/locales/views/sessions/it.yml`
```ruby
it: 
  sessions:
    new:
      title: Log In
      submit: Log In
```


Riavviamo il server Rails in modo che carichi questi files. Dopo averlo fatto, ricarichiamo la pagina e vedremo che  le stringhe localizzate sullo schermo.

#### Configurazione del modello

Con il form di accesso creato, iniziamo a lavorare a livello modello. Il token di sessione verrà inserito in un nuovo modello. Sarà protetto utilizzando `has_secure_password`, garantendo che un aggressore non possa utilizzare i token per impersonare gli utenti in caso di compromissione del database.

Il nuovo modello si chiamerà `AppSession`. Questo nome evita confusioni con la `sessione` di Rails, che è un cookie speciale criptato utilizzato per archiviare dati temporanei per un uso a breve termine. Un utente avrà molte `AppSessions`, consentendo all'utente di essere connesso da dispositivi o browser multipli contemporaneamente.

Generiamo un modello e una migrazione per `AppSession`.

```sh
bin/rails g model AppSession user:references token_digest:string
```
Il generatore crea anche un file di fixture superfluo. Eliminiamolo.
```sh
rm test/fixtures/app_sessions.yml
```

Eseguiamo la migrazione del database per creare la tabella `app_sessions`

```sh
bin/rails db:migrate
```

Il modello `app/models/app_session.rb` sarà piuttosto elementare. Il suo unico scopo è memorizzare in modo sicuro un token generato casualmente. Il token non deve essere passato da nessuna parte, quindi lo creeremo in un callback `before_create`. 
Implementiamo tutto  questo come mostrato di seguito:

`app/models/app_session.rb

```ruby
class AppSession < ApplicationRecord
  belongs_to :user

  has_secure_password :token, validation: false

  before_create {
    self.token = self.class.generate_unique_secure_token
  }
end

```

Come visto nel [capitolo precedente](/documentation/chapter3/user_model.md), `has_secure_password` di default scrive su una colonna `password_digest`. Questo non ha molto senso in questo caso, quindi passiamo un parametro esplicito di `:token` a `has_secure_password`. Questo crea un attributo `token` da utilizzare in memoria e scrive il valore hash nella colonna `token_digest`.

La validazione è disabilitata utilizzando `validations: false` poiché il `token` viene generato internamente dal model prima di essere salvato. Senza di ciò, la validazione del modello fallirebbe e non verrebbe mai salvato.

Il `token` viene generato utilizzando il pratico metodo di Active Record [generate_unique_secure_token](https://api.rubyonrails.org/classes/ActiveRecord/SecureToken/ClassMethods.html#method-i-generate_unique_secure_token). 

Aggiungiamo anche la relazione nel modello `User`:

`app/models/user.rb`

```ruby
class User < ApplicationRecord
  #...
  validates :password, presence: true, length: {minimum: 8}

  has_many :app_sessions

  #...
end
```

Prima che questa funzionalità possa essere testata, avremo bisogno di alcuni utenti nel nostro database di test. Le fixture di Rails sono il modo più semplice per creare un set di dati generico da utilizzare nei test. Sono scritte in YAML, ma è possibile utilizzare anche ERB al loro interno. Aggiungi alcuni utenti di test come mostrato nel codice seguente:

`test/fixtures/users.yml`

```ruby
jerry:
  name: Jerry
  email: jerry@example.com
  password_digest: <%= BCrypt::Password.create("password") %>

kramer:
  name: Kramer
  email: kramer@example.com
  password_digest: <%= BCrypt::Password.create("password") %>

elaine:
  name: Elaine
  email: elaine@example.com
  password_digest: <%= BCrypt::Password.create("password") %>

george:
  name: George
  email: george@example.com
  password_digest: <%= BCrypt::Password.create("password") %>
```

Dato che stiamo creando utenti, è necessario creare anche le fixture predefinite per le loro `Organization` e `Membership`. Compiliamo le fixture come mostrato nel file seguente:

Creiamo le `fixture` predefinite dell'Organizzazione per ciascun utente
`test/fixtures/organizations.yml`

```ruby
jerry: {}
kramer: {}
elaine: {}
george: {}

```
Creiamo le `fixture`  per le `Membership` per collegare un utente con la sua organizzazione:
`test/fixtures//memberships.yml`

```ruby
jerry:
  user: jerry
  organization: jerry

kramer:
  user: kramer
  organization: kramer

elaine:
  user: elaine
  organization: elaine

george:
  user: george
  organization: george
```

Con i dati di test caricati, scriviamo un test per verificare che `AppSession` genera e salva un token quando viene creato.
Modifichiamo il file seguente `test/models/app_session_test.rb`:

```ruby
require "test_helper"

class AppSessionTest < ActiveSupport::TestCase
  setup do 
    @user = users(:antonino)
  end

  test "token is generated and saved when a new record is created" do
    app_session = @user.app_sessions.create

    assert app_session.persisted?
    assert_not_nil app_session.token_digest
    assert app_session.authenticate_token(app_session.token)
  end

end
```

Notiamo che nel file appena modificato(`test/models/app_session_test.rb`) viene chiamato `authenticate_token`, invece di `authenticate` come nel caso della password. Questo è reso necessario dal fatto che `has_secure_password` ha un attributo personalizzato.

Eseguiamo il test:

```sh
bin/rails test
```
Tutti i test sono passati! 

#### Il form di accesso

Ora che abbiamo un modello con cui lavorare, possiamo far sì che il `form` di accesso faccia qualcosa. Il `form` punta al percorso di accesso (`login_path`) e poiché nessun metodo è specificato esplicitamente, sarà di tipo `POST`. Cominciamo definendo una route per questa richiesta nel file `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  #...
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
end
```

Aggiungiamo l'azione `create` al controller corrispondente.

`app/controllers/sessions_controller.rb`

```ruby
class SessionsController < ApplicationController
    def new
    end

    def create
    end
end
```

L'azione `create` è responsabile per l'accesso di un utente in `Shoopping Gioioso`. La logica di autenticazione può essere suddivisa nei seguenti passaggi:

1. Verificare le credenziali di accesso (`email` e `password`).

2. Creare un nuovo record di `AppSession`.

3. Archiviare l'id dell'utente, il `token` di `AppSession` e l'id di `AppSession` in un cookie crittografato.

Iniziamo con i Passaggi 1 e 2. Questa logica appartiene al modello `User` poiché è lì che si trovano l'`email` e la `password`. Definiremo un metodo di classe su `User` per verificare le credenziali di accesso e creare una nuova `AppSession` se sono valide. 

Tuttavia, prima di scrivere il codice dell'applicazione, iniziamo scrivendo alcuni test che falliranno.   

*Test sulla creazione di nuove AppSessions.*
`test/models/user_test.rb`

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  #...

  test "can create a session with email and corret password" do
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

      assert_nil @app_session
    end

    test "creatin a session with non existent email returns nil" do
      @app_session = User.create_app_session(
        email: "asc@example.com",
        password: "WRONG"
      ) 

      assert_nil @app_session
    end
    
end
```

Chiamare `create_app_session` con credenziali valide dovrebbe restituire un'istanza di `AppSession`, altrimenti dovrebbe restituire `nil`. Se eseguiamo il test ora genererà un errore poiché quel metodo non esiste ancora. Andiamo ad aggingere il metodo `create_app_session` nel file `app/model/user.rb`

```ruby
class User < ApplicationRecord
  #...

  has_many :app_sessions


  def self.create_app_session(email:, password:)
      return nil unless user = User.find_by(email: email.downcase)

      user.app_session.create if user.authenticate(password)
  end
  #... 
end

```
Cerchiamo di trovare un utente utilizzando l'indirizzo email fornito e restituiamo `nil` se non esiste. Se l'utente viene trovato, viene autenticato con la password fornita e viene creata una nuova `AppSession` se è valida. L'azione `create` nel SessionsController può ora essere implementata come mostrato nel file seguente:
`app/controllers/sessions_controller.rb`

```ruby
class SessionsController < ApplicationController
    def new
    end

    def create
        
        @app_session = User.create_app_session(email: login_params[:email],password: login_params[:password])
        if @app_session
            # TODO: Store details in cookie
            flash[:success] = t(".success")
            redirect_to root_path, status: :see_other
        else
            flash.now[:danger] = t(".incorrect_details")
            render :new, status: :unprocessable_entity
        end

    end

    private
    def login_params
        @login_params ||=params.require(:user).permit(:email, :password)
    end

end

```

Affronteremo la logica per archiviare i dettagli dell'utente in un cookie un po' più tardi, quindi è una buona idea lasciare un `TODO`: al suo posto. Ci sono un paio di stringhe rivolte all'utente da aggiungere al dizionario delle traduzioni locali.

`config/locales/views/sessions/en.yml`

```ruby
en: 
  sessions:
    new:
      title: Log In
      submit: Login
    create:
      success: You're logged in!
      incorret_details: The email or password was incorrect. Please try again.

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
      incorret_details: L'indirizzo email o la password non sono corretti. Per favore, riprova.
```

Dovremmo ora essere in grado di effettuare l'accesso come l'utente che hai creato nel capitolo precedente! Proviamo il modulo di accesso sia con credenziali valide che non valide e dovremmo vedere le schermate mostrate nelle immagini seguenti:

![Log In - Error - Shopping Gioioso](/documentation/chapter4/images/login-errors.png "Login form error - Shopping Gioioso ")

![Log In - Success - Shopping Gioioso](/documentation/chapter4/images/login-success.png "Login form success - Shopping Gioioso ")

Dal punto di vista dell'utente, sembra che siano connessi, ma non abbiamo ancora archiviato nulla in un cookie. Per quanto riguarda l'applicazione, sono ancora disconnessi. Costruiremo questa funzionalità nella prossima sezione. 
Prima di questo, completiamo `SessionsController` con alcuni test.

`test/controllers/sessions_controller_test.rb`
```ruby
require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  
  setup do
    @user = users(:jerry)
  end

  test "user is logged in and redirected to home with correct credentials" do

    assert_difference("@user.app_sessions.count", 1) {
      post login_path, params: {
        user: {
          email: "jerry@example.com",
          password: "password"
          }
        }
      }

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

end
```

#### Un `concern` per l'autenticazione

Per completare il processo di `autenticazione`, i dati dell'utente devono essere archiviati in un cookie crittografato e tali dati devono essere verificati in ogni richiesta. Dovremo sapere se l'utente è connesso per quasi ogni controller.

Una delle opzioni è implementare questa logica nell'`ApplicationController`, tuttavia questa strada può diventare scivolosa e l'`ApplicationController` può diventare molto confusionario man mano che l'applicazione cresce. Considero una buona pratica avere poca o nessuna logica nell'`ApplicationController`. Invece, la logica dovrebbe essere inserita in un `concern` che viene incluso nell'`ApplicationController`.


#####  "Cosa è un `concern`?

> Un `concern` è fornito dalla libreria `Active Support` (che è inclusa in Rails) sopra un modulo Ruby. Ci consente di scrivere e raggrupare codice da includere in altre classi.
I `concern` possono essere scritti per essere riutilizzati o per l'uso in una singola classe.
Per ulteriori informazioni, consulta la documentazione di Rails sui [Concerns](https://api.rubyonrails.org/classes/ActiveSupport/Concern.html)


Creiamo un `concern` per l'`autenticazion` e quindi lo includiamo nell'`ApplicationController`

```sh
touch app/controllers/concerns/authenticate.rb
```
Apriamo il file appena creato e dichiariamo il `concern` **Authenticate**

`app/controllers/concerns/authenticate.rb`

```ruby
module Authenticate
    extend ActiveSupport::Concern
end
```

Includiamo il `concern` Authenticate nell'`ApplicationController`

```ruby
class ApplicationController < ActionController::Base
    include Authenticate
end
```
Iniziamo a costruire il concern `Authenticate`. Il primo passo è scrivere un metodo per archiviare i dati dell'utente in un cookie crittografato. Tre pezzi di dati devono essere archiviati nel `cookie` per l'`autenticazione`:

1. L'ID dell'utente (User).
2. L'ID di AppSession.
3. Il token di AppSession.

Poiché il `token` di `AppSession` è archiviato come un hash, il record non può essere recuperato utilizzando direttamente il token. Ecco perché l'`ID` deve essere archiviato nel cookie. Il record può quindi essere recuperato utilizzando il suo `ID` e autenticato utilizzando il `token`.

Tutti i dati sopra menzionati sono disponibili nel modello `AppSession`, quindi scriveremo un metodo per convertire quell'oggetto in un hash come mostrato nel file `app/models/apps_session.rb`. Il metodo `log_in`  per archiviare l'hash in un cookie crittografato sarà definito nel file `app/controllers/concerns/authenticate.rb`

Quindi scriviamo un metodo per convertire un  oggetto `AppSession` in un `hash`:

`app/models/app_session.rb`

```ruby
class AppSession < ApplicationRecord
  #...

  def to_h
    {
      user_id = user.id,
      app_session = id,
      token: self.token
    }
  end

end

```
E un  metodo per archiviare i dati dell'utente in un `cookie` crittografato:

`app/controllers/concerns/authenticate.rb`

```ruby
module Authenticate
    extend ActiveSupport::Concern
    
    protected
    def log_in(app_session)
        cookies.encrypted.permanent[:app_session] = {value: app_session.to_h}
    end
end
```

Poiché il concern `Authenticate` è incluso nell'`ApplicationController` e tutti i metodi pubblici in un controller Rails sono considerati azioni, il metodo `log_in` nel file `app/controllers/concerns/authenticate.rb` è dichiarato come `protected`.

Abbiamo utilizzato un `helper` di Rails per archiviare i dati in un cookie crittografato ed è anche collegato al `permanent cookie jar`, il che significa che il cookie rimarrà attivo per 20 anni. In questo modo, l'utente non verrà disconnesso se chiude il browser o l'app.

Ora possiamo tornare indietro e affrontare gli `TODO stubs` nei controller `SessionsController` e `UsersController`.

*Effettua l'accesso dell'utente quando le sue credenziali sono valide.* 
`app/controllers/sessions_controller.rb`

```ruby
class SessionsController < ApplicationController
#...
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
  #...
end
```

*Effettua l'accesso di un nuovo utente dopo che ha creato un account.*
`app/controllers/users_controller.rb`

```ruby
class UsersController < ApplicationController
 #...

  def create
    @user = User.new(user_params)
    if @user.save
      @organization = Organization.create(members: [@user])
      @app_session = @user.app_sessions.create
      log_in(@app_session)
      
      redirect_to root_path,
        status: :see_other,
        flash: {success: t(".welcome", name: @user.name)}
    else
        render :new, status: :unprocessable_entity
    end
  end

  #...
end

```

I test devono anche essere aggiornati per verificare che l'utente sia effettivamente connesso in entrambi i casi sopra descritti.

*Aggiungiamo un controllo per verificare i dati validi nel cookie dopo un accesso*

`test/controllers/sessions_controller_test.rb`

```ruby
require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  
  #...

  test "user is logged in and redirected to home with correct credentials" do

    assert_difference("@user.app_sessions.count", 1) {
      post login_path, params: {
        user: {
          email: "jerry@example.com",
          password: "password"
          }
        }
      }
      assert_not_empty cookies[:app_session]
      assert_redirected_to root_path
  end

  #...
end
```
*Aggiungiamo un controllo per assicurarsi che un utente sia connesso dopo essersi registrato*
`test/controllers/user_controller_test.rb`

```ruby
require "test_helper"

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
    assert_not_empty cookies[:app_session]
    follow_redirect!
    assert_select ".notification.is-success", text: I18n.t("users.create.welcome", name: "John")

  end

 #...
end
```

Lanciamo nuovamente i test:
```sh
bin/rails test
```
Perfetto! Tutti i nostri test sono passati!

Questo completa metà del compito. Ora i dati dell'utente sono sicuramente salvati in un cookie. Successivamente, questi dati devono essere autenticati in ogni richiesta. Una volta che un utente è stato autenticato, l'oggetto `User` dovrà essere accessibile ovunque nell'applicazione. Un modo comune per farlo in passato era avere un metodo `current_user` creato  nell' `ApplicationController`.

Rails 5 ha introdotto una classe chiamata `ActiveSupport::CurrentAttributes`, che è sottoclassata in una classe `Current` per l'uso. Ciò ci consente di impostare attributi globali per ogni richiesta. 
Questa costruzione dovrebbe essere utilizzata con estrema cautela e solo per oggetti che sono veramente globali all'interno del contesto di una richiesta.

La documentazione per questa classe afferma quanto segue:

> Una parola di cautela: è facile esagerare con un singleton globale come `Current` e intrecciare il tuo modello di conseguenza. `Current` dovrebbe essere utilizzato solo per pochi oggetti globali di alto livello, come dettagli di account, utente e richiesta. Gli attributi memorizzati in 'Current' dovrebbero essere utilizzati più o meno da tutte le azioni in tutte le richieste. Se inizi a inserire attributi specifici del controller lì dentro, creerai un pasticcio.

Indubbiamente, un oggetto `User` si qualifica come globale. Insieme all'`User`, archivieremo anche `AppSession` e `Organization` in `Current`, poiché sono strettamente correlati all'User e si qualificano anche come oggetti globali.
Creiamo un nuovo file `app/models/current.rb` 
```sh
touch app/models/current.rb
```
e compilalo con il seguente contenuto:

```ruby
class Current < ActiveSupport::CurrentAttributes
    attribute :user, :app_session, :organization
end
```
Siamo ora pronti per implementare la logica per autenticare i dati del cookie e recuperare l'utente corrente, come mostrato nel file seguente:
`app/controllers/concerns/authenticate.rb`

```ruby
module Authenticate
    extend ActiveSupport::Concern
    
    #...


    private
    def authenticate
        Current.app_session = authenticate_using_cookie
        Current.user = Current.app_session&.user
    end

    def authenticate_using_cookie
        app_session = cookies.encrypted[:app_session]
        authenticate_using app_session&.with_indifferent_access
    end

    def authenticate_using(data)
        data => { user_id:, app_session:, token: }
        user = User.find(user_id)
        user.authenticate_app_session(app_session, token)
    rescue NoMatchingPatternError, ActiveRecord::RecordNotFound
        nil
    end
end
```

C'è abbastanza lavoro in corso, quindi procediamo un metodo alla volta. In primo luogo, tutti i metodi sono dichiarati come `privati` invece di protetti perché non sono destinati a essere chiamati da fuori di questo `concern`. Ora diamo un'occhiata al metodo `authenticate`:

```ruby
def authenticate
  Current.app_session = authenticate_using_cookie
  Current.user = Current.app_session&.user
end
```

L'utente viene autenticato utilizzando un cookie. Se ha successo, `Current.app_session` e `Current.user` vengono assegnati. Se in futuro fossero necessari altri metodi di autenticazione, possono essere concatenati utilizzando un operatore OR, come mostrato di seguito:


```ruby
def authenticate
  Current.app_session = authenticate_using_cookie || authenticate_using_token
  Current.user = Current.app_session&.user
end
```

Successivamente, approfondiamo il metodo `authenticate_using_cookie`:

```ruby
def authenticate_using_cookie
    app_session = cookies.encrypted[:app_session]
    authenticate_using app_session&.with_indifferent_access
end 
```

Questo metodo estrae i dati dal cookie crittografato e, mentre li passa al metodo `authenticate_using`, li converte in un hash con accesso indifferente. Ciò significa che i valori possono essere recuperati sia utilizzando la versione stringa che simbolica della chiave.

`authenticate_using` è il cuore di questa procedura, quindi esaminiamo quel metodo riga per riga.

```ruby
def authenticate_using(data)
  data => { user_id:, app_session:, token: }

  user = User.find(user_id)
  user.authenticate_app_session(app_session, token)
rescue NoMatchingPatternError, ActiveRecord::RecordNotFound
  nil
end   
```

La prima riga destruttura l'hash in variabili utilizzando la sintassi di assegnazione verso destra di Ruby 3. Se l'hash non può essere destrutturato utilizzando i simboli specificati, verrà generata un'eccezione `NoMatchingPatternError`. In questo contesto, ciò significa che l'autenticazione non è riuscita. L'errore viene gestito(`rescue`) e viene restituito `nil`.

Successivamente, l'utente viene recuperato utilizzando `user_id` , tenendo conto nuovamente del caso in cui il record non possa essere trovato, gestendo l'errore e restituendo `nil`.

E infine, l'oggetto `User` viene utilizzato per autenticare l'`app_session` e il `token`, restituendo un'istanza di `AppSession` se ha successo e `nil` se non ha successo. Questo non funzionerà ancora perché `User` non ha un metodo chiamato `authenticate_app_session`

Scriviamo prima alcuni test per questo:

*Test del metodo `authenticate_app_session`*
`test/models/user_test.rb`

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
#...
  test "creating a session with non existent email returns nil" do
    @app_session = User.create_app_session(
      email: "asc@example.com",
      password: "WRONG"
    ) 

    assert_nil @app_session
  end

  test "can authenticate with a valid session id and token" do
    @user = users(:jerry)
    
    @app_session = @user.app_sessions.create
    assert_equal @app_session,
    @user.authenticate_app_session(@app_session.id, @app_sessio.token)
  end

  test "trying to authenticate with a token that doesn't exist returns false" do
    @user = users(:jerry)
    
    assert_not @user.authenticate_app_session(50, "token")  
  end

end

```

L'implementazione è dimostrata in `app/models/user.rb`

```ruby
class User < ApplicationRecord
   #...
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
end
```

Passando l'`app_session_id` , è possibile recuperare l'istanza corretta di `AppSession` e autenticarla dalle `app_sessions` dell'utente.

#### Autenticazione in tutta l'applicazione.

Con il meccanismo di autenticazione ora in atto, tutto ciò che dobbiamo fare è chiudere il cerchio chiamando il metodo `authenticate` globalmente. La pagina di **Log in** deve anche essere renderizzata per le richieste non autenticate. Alcune pagine possono essere visualizzate dagli utenti non connessi, quindi avremo bisogno di una valvola di scarico per saltare l'autenticazione dove necessario.

`ActiveSupport::Concern` ha un metodo `included` che accetta un blocco, il quale viene eseguito quando è incluso in una classe. Utilizzando questo metodo, definisci un callback per invocare 'authenticate', come mostrato nel file `app/controllers/concerns/authenticate.rb`:

```ruby
module Authenticate
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
    before_action :require_login, unless: :logged_in?
    helper_method :logged_in?
  end

  protected

    def logged_in?
      Current.user.present?
    end
  # ...

  private
    def require_login
      flash.now[:notice] = t("login_required")
      render "sessions/new", status: :unauthorized
    end
  # ...
end

```
Concentriamoci sul blocco `included` nel file `app/controllers/concerns/authenticate.rb` . Utilizzando i callback `before_action`, `authenticate` viene invocato prima di ogni azione del controller. Se l'utente non è connesso, il ciclo della richiesta viene interrotto dalla visualizzazione della pagina di accesso (`Log In`). Il metodo `logged_in?` è anche dichiarato come `helper_method`, in modo da poterlo utilizzare nelle viste.

Infine, dobbiamo definire le valvole di scarico per saltare l'autenticazione. Queste devono essere metodi di classe in modo che un controller possa invocarli nello stesso modo dei `callback`. Per farlo, utilizzeremo la direttiva `class_methods` di `ActiveSupport::Concern`, che accetta un blocco e aggiunge quei metodi alla classe ospite come metodi di classe.

`app/controllers/concerns/authenticate.rb`

```ruby
module Authenticate
    extend ActiveSupport::Concern

    included do
        before_action :authenticate
        before_action :require_login, unless: :logged_in?

        helper_method :logged_in?
    end

    class_methods do
        
        def skip_authentication(**options)
            skip_before_action :authenticate, options
            skip_before_action :require_login, options
        end

        def allow_unauthenticated(**options)
            skip_before_action :require_login, options
        end
        
    end
    #...
  end
```

`skip_authentication` salta completamente il processo di autenticazione e verrà utilizzato per la pagina di accesso (**Log In**). `allow_unauthenticated` autentica la richiesta ma non interrompe il ciclo della richiesta per le richieste non autenticate. Questo verrà utilizzato per le pagine che devono sapere se un utente è connesso, ma che sono anche visibili agli utenti non connessi. Lo utilizzeremo per il feed principale, che è la pagina di atterraggio e visibile a tutti gli utenti indipendentemente dallo stato di registrazione o accesso.

Questi metodi accettano anche un hash di opzioni che viene passato alla chiamata di `skip_before_action`; ciò significa che questa invocazione del metodo può essere limitata a azioni specifiche o basata su condizioni specifiche esattamente come i `callback` dei controller di Rails.

Adesso aggiungiamo una nuoca stringa localizzata globale nel file per la lingua inglese  `config/locales/globals/en.yml` e nel file per la lingua italiana `config/locales/globals/it.yml`:

`config/locales/globals/en.yml`

```ruby
en:
  hello: Hello World!
  goodbye: Goodbye.
  app_name: Shopping Gioioso
  login_required: You need to log in to view this page!
```

`config/locales/globals/it.yml`
```ruby
it:
  hello: Ciao!
  goodbye: Arrivederci.
  app_name: Shopping Gioioso
  login_required: Devi effettuare l'accesso per visualizzare questa pagina!
```

Se eseguiamo i test ora, vedremo che la nostra suite di test è fallita (i test sono andati in errore).

```sh
bin/rails test
```

Un'ispezione più approfondita degli errori rivela che sono causati da risposte inaspettate `401 Unauthorized`. Questo perché l'autenticazione è abilitata globalmente senza eccezioni. Deve essere saltata per le azioni che coinvolgono la `registrazione` e l'`accesso`, poiché l'utente non sarà connesso quando visualizzerà quelle pagine. Le richieste non autenticate devono anche essere consentite sulla pagina iniziale *`home feed`*.

*Saltiamo l'autenticazione nel modulo di creazione di un nuovo utente.*
`app/controllers/users_controller.rb`

```ruby
class UsersController < ApplicationController
  skip_authentication only: [:new, :create]
  #...
end
```

*Saltiamo l'autenticazione nel modulo di accesso (`login`)*

`app/controllers/sessions_controller.rb`

```ruby
class SessionsController < ApplicationController
    skip_authentication only: [:new, :create]
    #...
end
```

*Consentiamo richieste non autenticate sulla pagina iniziale (`home feed`).*

`app/controllers/feed_controller.rb`
```ruby
class FeedController < ApplicationController
  allow_unauthenticated
  
  def show
  end
end
```

Eseguiamo nuovamente i test:

```sh
bin/rails test
```

Tutti i test dovrebbero essere eseguiti con successo!


