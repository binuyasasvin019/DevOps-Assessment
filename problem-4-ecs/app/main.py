
from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI(
    title="DevOps Assessment App",
    docs_url=None,
    redoc_url=None,
)


@app.get("/", response_class=HTMLResponse)
def home():
    return """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <title>DevOps Assessment</title>
      </head>
      <body>
        <h1>DevOps Assessment Application</h1>
        <p>Running with FastAPI, Uvicorn and Nginx.</p>
      </body>
    </html>
    """


@app.get("/health/live")
def liveness():
    return {"status": "alive"}


@app.get("/health/ready")
def readiness():
    return {"status": "ready"}
