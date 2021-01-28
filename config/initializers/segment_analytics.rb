require 'segment/analytics'

SegmentAnalytics = Segment::Analytics.new(write_key: ENV['SEGMENT_KEY'],
                                          on_error: Proc.new { |_status, msg| print msg })
