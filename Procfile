web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bin/jobs
release: bin/rails db:prepare && DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load:cache db:schema:load:queue db:schema:load:cable
