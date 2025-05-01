# Raffley

To start your Phoenix server on VPS!:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit `localhost:4000` from your browser.

Ready to run in production? Please check our deployment guides.

## Learn more for version 1.8-rc.1 to try, 2nd option better because you don't install.
* `mix archive.install hex phx_new 1.8.0-rc.1 --force`
* or `curl https://new.phoenixframework.org/<myapp> | sh`


## Resend Configuration (for Production)

1.  **Add Resend Dependency:** Ensure `{:resend, "~> 0.4.4"}` is in your `mix.exs` dependencies and run `mix deps.get`.

2.  **Configure in `runtime.exs`:** Add the following lines inside the `if config_env() == :prod do` block in your `config/runtime.exs` file:

    ```elixir
    # config/runtime.exs (inside :prod block)

    config :raffley, Raffley.Mailer,
      adapter: Resend.Swoosh.Adapter,
      api_key: System.fetch_env!("RESEND_API_KEY")

    # Use Finch for the Swoosh API client in production
    config :swoosh, :api_client, Swoosh.ApiClient.Finch
    ```

3.  **Set Sender Email:** In `lib/raffley_web/emails/user_notifier.ex` (or wherever your mailer functions are defined), make sure the `:from` address is set to an email address associated with a domain you have verified in Resend.

4.  **Set Environment Variable:** Ensure the `RESEND_API_KEY` environment variable is set in your production environment (e.g., in your `.env` file or systemd service definition). Get this key from your Resend account dashboard.

**Note:** During development (`MIX_ENV=dev`), emails will typically be delivered to the local mailbox viewer (usually accessible via `/dev/mailbox`) unless you specifically configure Resend for development as well.

## Setting up SSH Key for Deployment (GitHub Actions)

If you are using GitHub Actions to deploy, you'll likely need an SSH key pair to allow the Action runner to connect to your VPS.

1.  **Generate SSH Key Pair:**
    On your local machine (or anywhere secure, **not** on the VPS itself), generate a new SSH key pair. It's good practice to use a specific key for deployment and protect it with a passphrase (though you'll need to handle the passphrase during deployment if you use one).
    ```bash
    # Use -f to specify a filename, e.g., deploy_key
    # You can choose to add a passphrase when prompted
    ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/deploy_key_raffley
    ```
    This creates two files: `~/.ssh/deploy_key_raffley` (private key) and `~/.ssh/deploy_key_raffley.pub` (public key).

2.  **Add Public Key to VPS:**
    Copy the contents of the **public key** (`~/.ssh/deploy_key_raffley.pub`) and add it as a new line to the `~/.ssh/authorized_keys` file on your VPS for the user the deployment will connect as (e.g., `ubuntu`).
    ```bash
    # On your local machine, display the public key
    cat ~/.ssh/deploy_key_raffley.pub

    # On your VPS (replace 'ubuntu' if using a different user)
    # SSH into your VPS first, then run:
    echo "PASTE_PUBLIC_KEY_CONTENT_HERE" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys # Ensure correct permissions
    ```

3.  **Get Private Key Content:**
    You need the content of the **private key** (`~/.ssh/deploy_key_raffley`) to store it in GitHub Secrets. Display its content:
    ```bash
    # On your local machine
    cat ~/.ssh/deploy_key_raffley
    ```

4.  **Set GitHub Secret:**
    *   Copy the entire output from the `cat` command above (including the `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` lines).
    *   Go to your GitHub repository.
    *   Navigate to `Settings` > `Secrets and variables` > `Actions`.
    *   Click `New repository secret`.
    *   Name the secret `VPS_SSH_PRIVATE_KEY`.
    *   Paste the copied private key content into the `Secret` value box.
    *   Click `Add secret`.

Now your GitHub Actions workflow can use `${{ secrets.VPS_SSH_PRIVATE_KEY }}` to authenticate SSH connections to your VPS.


## Exclusively using Magic Link

* Registration disabled through web, done through `iex -S mix` on VPS
* `alias Raffley.Accounts`
* `user_params = %{"email" => "new_user@example.com"}` # Add any other required fields
* `Accounts.register_user(user_params)`
* Then log in on the VPS
* If running on localhost, do the same as above

## sudo nano /etc/systemd/system/raffley.service

* User=ubuntu
* Group=ubuntu
* WorkingDirectory=/home/ubuntu/raffley
* Restart=on-failure
* ExecStart=/home/ubuntu/raffley/_build/prod/rel/raffley/bin/raffley start
* Environment="PORT=4001"
* Environment="SECRET_KEY_BASE=xxxxxxxx"
* Environment="DATABASE_URL=ecto://:user:password@localhost/db"
* Environment="RESEND_API_KEY=re_xxxxxxxxxx"
* Restart=always
* RemainAfterExit=yes
* [Install]
* WantedBy=multi-user.target

## Raffley Service

* sudo systemctl daemon-reload
* sudo systemctl enable raffley.service
* sudo systemctl start raffley.service

## sudo nano /etc/nginx/sites-available/raffley

server {
    server_name applikasi.tech www.applikasi.tech;

    # Serve static assets directly
    location /images/ {
        alias /home/ubuntu/raffley/priv/static/images/;
        expires 1y; # Cache static assets for 1 year
        add_header Cache-Control "public";
    }

    # Serve static files (Phoenix assets)
    location /assets/ {
        alias /home/ubuntu/raffley/priv/static/assets/;
        expires 30d;  # Cache static files for 30 days
        add_header Cache-Control "public";
    }

    # Proxy other requests to Phoenix
    location / {
        proxy_pass http://localhost:4001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}# <-- This closing brace was missing from copy/paste

* sudo ln -s /etc/nginx/sites-available/raffley /etc/nginx/sites-enabled/
* sudo nginx -t # Test configuration
* sudo systemctl restart nginx



## Build for app raffley

* mix phx.gen.release # only one time to generate release for migration
* MIX_ENV=prod mix compile
* MIX_ENV=prod mix assets.deploy
* MIX_ENV=prod mix release
* cd _build/prod/rel/raffley
* bin/raffley remote
* Raffley.Release.migrate()

## Get certs from certbot

* sudo apt update
* sudo apt install certbot python3-certbot-nginx -y
* sudo certbot --nginx

## Phoenix Framework Links

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
