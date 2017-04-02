from itertools import groupby
from operator import attrgetter
from datetime import timedelta
from django.shortcuts import render

from django.views.generic.list import ListView
from django.views.generic.detail import DetailView
from django.db.models import Sum, Min, Max
from django.urls import reverse

from .models import NodeSeen, AccessPoint

from .time_blocks import reduce_time_block


class NodeSeenListView(ListView):
    model = NodeSeen

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)

        nodes_per_ap = []

        for ap_bssid, ap_name in AccessPoint.objects.values_list('bssid', 'name').distinct():
            nodes = NodeSeen.objects.filter(bssid=ap_bssid).values('mac_address').annotate(
                times_seen_sum=Sum('times_seen'), first_seen=Min('first_seen'), last_seen=Max('last_seen'))
            for node in nodes:
                node.update({
                    'url': reverse('nodeseen-detail', args=(node.get('mac_address'),)),
                })

            nodes_per_ap.append({
                'ap': '{} ({})'.format(ap_name, ap_bssid),
                'nodes': list(nodes)
            })
        context['nodes_per_ap'] = nodes_per_ap
        return context


class NodeSeenDetailView(ListView):
    model = NodeSeen
    template_name = 'addresses/nodeseen_detail.html'

    def get_queryset(self):
        return super().get_queryset().filter(mac_address=self.kwargs.get('mac_address'))

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        ap_mapping = {bssid: name for bssid, name in AccessPoint.objects.values_list('bssid', 'name').distinct()}
        bssids = []
        prev_block = None
        next_block = None
        for bssid, nodes in groupby(self.object_list.order_by('bssid', 'start_block'), key=attrgetter('bssid')):
            bssids.append({
                'bssid': bssid,
                'name': ap_mapping.get(bssid, 'Onbekend'),
                'blocks': list(reduce_time_block(nodes)),
            })
        context['bssids'] = bssids
        return context

