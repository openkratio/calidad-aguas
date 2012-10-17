class SamplePoint:
  name = ''
  x = 0
  y = 0
  zone = 0
  beach = None

  def __str__(self):
    return "%s zone:%d x:%d y:%d beach:%s" % (self.name, self.zone, self.x, self.y, self.beach)
