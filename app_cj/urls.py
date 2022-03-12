from django.urls import path

from . import views

urlpatterns = [
    path('mainpage', views.index, name='index'),
    path('submit-request', views.submit,name='submit'),
]