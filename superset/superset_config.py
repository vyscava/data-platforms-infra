import os
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

def get_env_variable(var_name, default=None):
    """Get the environment variable or raise exception."""
    try:
        return os.environ[var_name]
    except KeyError:
        if default is not None:
            return default
        else:
            error_msg = 'The environment variable {} was missing, abort...' \
                .format(var_name)
            raise EnvironmentError(error_msg)

# Configure Flask-Limiter with Redis as storage backend
limiter = Limiter(
    key_func=get_remote_address,
    storage_uri="redis://redis:6379"
)

# https://superset.apache.org/docs/configuration/cache/
FILTER_STATE_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,
    'CACHE_KEY_PREFIX': 'superset_filter_cache',
    'CACHE_REDIS_URL': 'redis://redis:6379/0'
}

CELERY_CONFIG = {
  'broker_url': 'redis://redis:6379/0',
  'result_backend': 'redis://redis:6379/0'
}

# Superset specific config
ROW_LIMIT = 5000

# Flask App Builder configuration
# Your App secret key will be used for securely signing the session cookie
# and encrypting sensitive information on the database
# Make sure you are changing this key for your deployment with a strong key.
# Alternatively you can set it with `SUPERSET_SECRET_KEY` environment variable.
# You MUST set this for production environments or the server will refuse
# to start and you will see an error in the logs accordingly.
SECRET_KEY = ''

# The SQLAlchemy connection string to your database backend
# This connection defines the path to the database that stores your
# superset metadata (slices, connections, tables, dashboards, ...).
# Note that the connection information to connect to the datasources
# you want to explore are managed directly in the web UI
# The check_same_thread=false property ensures the sqlite client does not attempt
# to enforce single-threaded access, which may be problematic in some edge cases
# SQLALCHEMY_DATABASE_URI = 'sqlite:////path/to/superset.db?check_same_thread=false'

PSQL_HOST = get_env_variable('POSTGRESS_HOSTNAME')
PSQL_HOST_PORT = get_env_variable('POSTGRESS_HOSTNAME_PORT')
PSQL_USER = get_env_variable('PSQL_SUPERSET_USER')
PSQL_PASSWORD = get_env_variable('PSQL_SUPERSET_PASSWORD')
PSQL_DB = get_env_variable('PSQL_SUPERSET_DB')

SQLALCHEMY_DATABASE_URI = f'postgresql://{PSQL_USER}:{PSQL_PASSWORD}@{PSQL_HOST}:5434/{PSQL_DB}'

# Flask-WTF flag for CSRF
WTF_CSRF_ENABLED = True
# Add endpoints that need to be exempt from CSRF protection
WTF_CSRF_EXEMPT_LIST = []
# A CSRF token that expires in 1 year
WTF_CSRF_TIME_LIMIT = 60 * 60 * 24 * 365

# Set this API key to enable Mapbox visualizations
MAPBOX_API_KEY = ''
