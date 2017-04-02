from django.contrib import admin
from .models import NodeSeen

# Register your models here.

@admin.register(NodeSeen)
class NodeSeenAdmin(admin.ModelAdmin):
    list_display = ('mac_address', 'start_block', 'first_seen', 'last_seen', 'times_seen')

