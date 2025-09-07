from app import create_app

# mod_wsgi looks for a callable named `application`
application = create_app()
