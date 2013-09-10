from fabric.api import local

def devel():
    local('jekyll --auto --serve 8000')

def build():
    local('jekyll')

def deploy():
    build()
    local('rsync -rtv _site/ techblog@rosedu.org:/home/techblog/techblog/content/_site/')
