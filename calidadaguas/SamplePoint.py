class SamplePoint:
  name = ''
  x = 0
  y = 0
  beach = None

  def __str__(self):
    return "%s x:%d y:%d beach:%s" % (self.name, self.x, self.y, self.beach)
