"""
Qweb app

- Render a simple index with a color background/
- Include the response to the sts get_client_indentifier API query.

"""
import json
import os
from datetime import datetime

from flask import Flask, render_template
from sts import caller_identity

application = Flask("qweb", template_folder=os.path.dirname(__file__))


@application.route("/")
def index():
    """
    Render the index.html with the information from the STS get_caller_identity query.
    """
    # The caller_identity variable is stored in the sts module in this way we create a simple singleton in that module
    # to store the API response and avoid creating multiples queries.
    current_date = datetime.utcnow().strftime("%a, %-d %b %Y %H:%M:%S GMT")  # Same format used in the API response.
    response = json.dumps(caller_identity, sort_keys=True, indent=4, separators=(",", ": "))

    return render_template("index.html", response=response, current_date=current_date)


# development
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    application.run(debug=True, host="0.0.0.0", port=port)
