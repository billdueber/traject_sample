require 'traject'
require 'socket'


settings do

  # This is just regular ruby, so don't be afraid to have conditionals!
  # Switch on hostname, for test and production server differences
  if Socket.gethostname =~ /devhost/
    provide "solr.url", "http://my.dev.machine:9033/catalog"
  else
    provide "solr.url", "http://my.production.machine:9033/catalog"
  end
  

  provide "solr_writer.commit_on_close", "true"
  provide "solr_writer.thread_pool", 1
  provide "solr_writer.batch_size", 100
  provide "writer_class_name", "Traject::SolrJsonWriter"
  
  provide 'processing_thread_pool', 3
end
