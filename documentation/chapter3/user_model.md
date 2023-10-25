
### Il modello `User` e le sue relazioni in Shopping Gioioso
Iniziamo a costruire la nostra applicazione creando un modulo di registrazione che consentirà ai nostri utenti di creare un account su **ShoppingGioioso**.

Questo sarà seguito dalla creazione di un sistema di autenticazione in modo che gli utenti possano effettuare il login e l'applicazione possa identificarli in modo sicuro.

Il primo passo è la creazioene dei modelli **User** e **Organization**


#### Modellazione di Utenti e Organizzazioni
Gli **utenti** costituiscono la parte principale della nostra applicazione web. L'altra è rappresentata dalle **Organizzazioni**. 
Un Utente appartiene a un'Organizzazione e tutte le risorse di dominio appartengono all'Organizzazione anziché al singolo Utente.

Di solito il concetto di organizzazioni è considerato al di fuori dal MVP(Minimum Viable Product). 
La gestione dei membri dell'organizzazione, l'assegnazione di ruoli e autorizzazioni, e un sistema di invito per unirsi a un'organizzazione sono tutte caratteristiche essenziali e non banali.

Tuttavia, nel contesto del modello di dominio, è fondamentale avere il concetto di un'Organizzazione. Altrimenti, tutte le risorse e le autorizzazioni sarebbero costruite intorno a un singolo Utente.

*MVP - Minimum Viable Product (Prodotto Minimo Funzionante) - Si riferisce a una versione iniziale di un prodotto che include solo le funzionalità più essenziali per soddisfare i requisiti minimi degli utenti.*

#### Modelli e tabelle del database
Un **Utente(User)**  dovrebbe poter appartenere a molte **Organizzazioni(Organization)**, e allo stesso tempo, un'**Organizzazione(Organization)** dovrebbe poter avere molti **Utenti**. Ciò significa che esiste un'associazione **many-to-many** tra questi due modelli che richiede una tabella di unione e un modello corrispondente. Questo modello sarà chiamato **"Membership"**. Genera i modelli e le migrazioni del database per queste entità.

```sh
 bin/rails g model User name:string email:string:uniq password_digest:string

 bin/rails g model Organization

 bin/rails g model Membership user:references organization:references

```


Il modello **Utente(User)** ha 3 campi di stringa per il **nome(name)**, l'**email** e il **password_digest**. 

Conservare la password come testo in chiaro rappresenta una falla di sicurezza nel caso in cui qualcuno riesca a ottenere un accesso non autorizzato al database, quindi viene conservata sotto forma di un **digest** sicuro generato utilizzando una libreria(**gemma**) chiamata **bcrypt**. 

Abbiamo anche creato un indice univoco per il campo dell'email in modo che non possano essere creati utenti duplicati.
Il modello **Organizzazione(Organization)** non ha campi al momento!

Infine, il modello **Membri(Membership)** fa riferimento alle chiavi esterne di **Utente(User)** e **Organizzazione(Organization)** ed ha lo scopo specifico di collegare questi due modelli. 
In futuro, se necessario, questo modello può essere ampliato per contenere informazioni come il ruolo che un **Utente** svolge all'interno di un'**Organizzazione**.

Adesso lanciamo la migrazioni:

```sh
bin/rails db:migrate
```

Cosi da creare le tabelle nel nostro database.


#### Validazioni e relazioni
Ora che i modelli sono pronti, aggiungiamo alcune **validazioni** e le **relazioni** per riflettere le chiavi esterne del database.

L'**utente** deve avere un nome e un'email valida e unica, quindi è necessario validare questi attributi.
Per il **nome(name)**, basta una semplice verifica di presenza, ma l'**email(email)** verrà convalidata utilizzando una **regex** incorporata.

Prima di inserire il codice necessario nel modello `User`, iniziamo con il test:

`test/models/user_test.rb`

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase

  test "requires a name" do
    @user = User.new(
      name: " ", 
      email: "antonino@example.com",
    )
    assert_not @user.valid?
    
    @user.name = "Antonino"
    assert @user.valid?
  end

  test "requires a valid email" do
    @user = User.new(
      name: "Antonino", 
      email: " ",
    )
    assert_not @user.valid?
    
    @user.email = "invalid"
    assert_not @user.valid?
    
    @user.email = "antonino@example.com"
    assert @user.valid?
  end
    
  test "requires a unique email" do
    @existing_user = User.create(
      name: "Antonino",
      email: "nino@example.com",
    )
    assert @existing_user.persisted?

    @user = User.new(
      name: "Nino", 
      email: "nino@example.com",
    )
    assert_not @user.valid?
  end

end

```

L'esecuzione di questi test fallirà poiché non abbiamo ancora scritto alcun codice dell'applicazione.

```sh
bin/rails test
```

Adesso scriviamo il codice dell'applicazione per far superare i test, come mostrato di seguito:

`app/models/user.rb`
```ruby
class User < ApplicationRecord
    validates :name, presence: true
    validates :email, 
        format: { with: URI::MailTo::EMAIL_REGEXP },
        uniqueness:{case_sensitive: false }
end

```

Eseguiamo il test nuovamente:
```sh
bin/rails test
```

La suite di test sarà ora passata!

Ora impostiamo le relazioni tra i modelli in modo da riflettere le chiavi esterne nel database.

*Un utente appartiene a molte organizzazioni(A User has many Organizations)*
`app/models/user.rb`
```ruby
class User < ApplicationRecord  
    # ...
    has_many :memberships, dependent: :destroy
    has_many :organizations, through: :memberships
end
```

*L'opzione **dependent: :destroy** per la relazione delle adesioni (**memberships**) è specificata in modo che la corrispondente adesione (**Membership**) venga eliminata quando un Utente viene eliminato. Faremo lo stesso per l'Organizzazione*

*Un'organizzazione ha molti utenti (An Organization has many Users)*
`app/models/organization.rb`
```ruby
class Organization < ApplicationRecord
    has_many :memberships, dependent: :destroy
    has_many :members, through: :memberships, source: :user
end

```

La relazione con l'Utente è definita come **has_many :members** perché **@organization.members** risulta più leggibile rispetto a **@organization.users**. L'opzione **source: :user** dice ad **ActiveRecord** di utilizzare la chiave esterna **user_id** per questa relazione.

*A Membership belongs to a User and an Organization*
`app/models/membership.rb`

```ruby
class Membership < ApplicationRecord
    belongs_to :user
    belongs_to :organization
end
```

#### Rimuovere spazi superflui

Un errore comune che le persone commettono quando compilano moduli web è quello di includere accidentalmente uno spazio all'inizio o alla fine di un campo. Questo non è sempre un problema, ma in un indirizzo email, uno spazio indesiderato può causare vari tipi di problemi. Aggiungiamo un metodo per rimuovere gli spazi nell'indirizzo email e nel nome.

`app/models/user.rb`
```ruby
class User < ApplicationRecord
# ...
    before_validation :strip_extraneous_spaces

    private
    def strip_extraneous_spaces
        self.name = self.name&.strip
        self.email = self.email&.strip
    end
end
```
L'uso del simbolo **"&"** sugli attributi viene fatto quando si chiama il metodo "strip" per essere sicuri nel caso in cui quegli attributi siano nulli. Non dovrebbero esserlo, ma se lo fossero, comunque causerebbero un errore di convalida e non dovrebbero generare un'eccezione.


#### Password sicure

Come accennato in precedenza, la password deve essere memorizzata in modo sicuro nel database sotto forma di un `digest`. Rails fornisce un `helper` chiamato `has_secure_password` per fare esattamente questo. Prima di poterlo utilizzare,la  gemma  `bcrypt` utilizzato per calcolare il digest deve essere aggiunto al progetto.

`Gemfile`

```ruby
# ...

# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"
# ...

```

Installa  la gemma `bcrypt` eseguendo il seguente comando:

```sh
bundle install
```

Oltre a proteggere la password, aggiungeremo anche una convalida per verificare la sua lunghezza e la sua presenza. Imposteremo un minimo di 8 caratteri per motivi di sicurezza.

Iniziamo con il test:

`test/models/user_test.rb`

```ruby
class UserTest < ActiveSupport::TestCase
    #...

    test " password length must be between 8 and ActiveModel's maximum" do
        @user = User.new(
            name: "Elena",
            email: "elena@example.com",
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

end

```
Sel lanciamo il test:

```sh
bin/rails test
```
vediamo che fallisce, perchè dobbiamo aggiornare il nostro modello.

Torniamo al modello `User` e aggiungiamo la convalida della password e la direttiva `has_secure_password` per garantire che sia memorizzata in modo sicuro. La convalida della lunghezza massima viene aggiunta automaticamente da Rails, quindi non è necessario definirla.

`app/models/user.rb`

```ruby
class User < ApplicationRecord
    # ...
    before_validation :strip_extraneous_spaces
    
    has_secure_password

    validates :password, presence: true, length: { minimum: 8 }

    private
    # ...
end
```

`has_secure_password` compatta molte funzionalità in una singola riga di codice. Si aspetta una colonna `password_digest` nel database e in modo trasparente `hashes` una password quando viene fornita durante la creazione o l'aggiornamento di un `Utente`!

Ora eseguiamo nuovamente la suite di test. È ancora `RED`!

```sh
bin/rails test
```

I test che verificano un nome ed un indirizzo email validi non vengono più superati. Ciò è dovuto all'aggiunta di una nuova convalida per una `password`, che non viene passata durante la creazione di un Utente in quei test. Questo è abbastanza semplice da correggere.

Quindi aggiorniamo il nostro test: `test/models/user_test.rb`

```ruby
class UserTest < ActiveSupport::TestCase

  test "requires a name" do
    @user = User.new(
      name: " ", 
      email: "antonino@example.com",
      password: "password"
    )
    assert_not @user.valid?
    
    @user.name = "Antonino"
    assert @user.valid?
  end

  test "requires a valid email" do
    @user = User.new(
      name: "Antonino", 
      email: " ",
      password: "password"
    )
    assert_not @user.valid?
    
    @user.email = "invalid"
    assert_not @user.valid?
    
    @user.email = "antonino@example.com"
    assert @user.valid?
  end
    
  test "requires a unique email" do
    @existing_user = User.create(
      name: "Antonino",
      email: "nino@example.com",
      password: "password"
    )
    assert @existing_user.persisted?

    @user = User.new(
      name: "Nino", 
      email: "nino@example.com",
      password: "password"
    )
    assert_not @user.valid?
  end
  #...
end
```

Adesso eseguiamo nuovamente:
```sh
bin/rails test
```
Adesso il nostro test è passato. Siamo pronti per la creazione del nostro form di registrazione.

