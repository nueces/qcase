"""
Gunicorn config variables
"""

loglevel = "info"
# Don't write any file, just drop everything to the standard outputs
errorlog = "-"  # stderr
accesslog = "-"  # stdout
# create the temp heartbeat files in memory.
worker_tmp_dir = "/dev/shm"
# as we are going to use a single worker is better to have a longer timeout to avoid that the arbiter restart it.
timeout = 120
# We are deploying behind a load balancer, so it;s better to have a longer keepalive than the default: 2
keepalive = 5
# Only one to avoid multiples call to the sts api, as each fork would import the module and create their own singleton
workers = 1
# a single thread would be able to serve hundreds of request but, there is always good to have some extra capacity :)
threads = 3
# bind in the standard http port
bind = "0.0.0.0:80"
