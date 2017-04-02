from django.db import models
from django.urls import reverse

from datetime import timedelta

class TimeBlockBase(models.Model):
    sensor = models.CharField(max_length=100)
    start_block = models.DateTimeField()
    duration = models.IntegerField()
    first_seen = models.DateTimeField()
    last_seen = models.DateTimeField()
    times_seen = models.IntegerField(default=1)

    class Meta:
        unique_together = (
            ('sensor', 'start_block'),
        )
        abstract = True

    @property
    def end_block(self):
        return self.start_block + timedelta(seconds=self.duration)


class AccessPoint(TimeBlockBase):
    bssid = models.CharField(max_length=100)
    name = models.CharField(max_length=255)

    class Meta(TimeBlockBase.Meta):
        unique_together = (
            list(TimeBlockBase._meta.unique_together[0]) + ['bssid', ],
        )


class NodeSeen(TimeBlockBase):
    mac_address = models.CharField(max_length=100)
    bssid = models.CharField(max_length=100)
    associated = models.BooleanField(default=False)

    class Meta(TimeBlockBase.Meta):
        unique_together = (
            list(TimeBlockBase._meta.unique_together[0]) + ['mac_address', 'bssid', ],
        )

    def get_absolute_url(self):
        return reverse('nodeseen_detail', args=(self.mac_address, ))


class NodeProbe(TimeBlockBase):
    mac_address = models.CharField(max_length=100)
    name = models.CharField(max_length=255)

    class Meta(TimeBlockBase.Meta):
        unique_together = (
            list(TimeBlockBase._meta.unique_together[0]) + ['mac_address', 'name', ],
        )
