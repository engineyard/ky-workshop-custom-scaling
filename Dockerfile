FROM engineyard/kontainers:ruby-2.5-v1.0.0
RUN apt-get install -y nodejs build-essential libxml2-dev libxslt-dev libpq-dev sqlite libsqlite3-dev  curl bash
 
# Install passenger
RUN gem install passenger -v "5.3.7"
RUN passenger-config install-standalone-runtime --auto

# Configure the main working directory. This is the base 
# directory used in any further RUN, COPY, and ENTRYPOINT 
# commands.
RUN mkdir -p /app 
WORKDIR /app


# Copy the Gemfile and Gemfile.lock
COPY Gemfile* ./
RUN gem install bundler -v '1.16.3' && bundle install --without development test --jobs 20 --retry 5

# Copy the main application.
COPY . ./

RUN chmod +x ky_specific/start_webserver_script.sh

# Expose port 5000 to the Docker host, so we can access it 
# from the outside. This is the same as the one set with
# `deis config:set PORT 5000`
EXPOSE 5000

# The main command to run when the container starts
CMD ls
