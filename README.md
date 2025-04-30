# Raffley

To start your Phoenix server on VPS!:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit `localhost:4000` from your browser.

Ready to run in production? Please check our deployment guides.

## Learn more for version 1.8-rc.1
## Exclusively using Magic Link
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
}

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
