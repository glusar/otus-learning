from django.http import HttpResponse


def home(request):
    return HttpResponse(
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Python application</title>
        </head>
        <body>
            <h1>Python application works!</h1>

            <p>Django: OK</p>
            <p>Gunicorn: OK</p>
            <p>Nginx: OK</p>
            <p>Docker: OK</p>
        </body>
        </html>
        """
    )