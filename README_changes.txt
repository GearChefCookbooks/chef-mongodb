1) The original flow for replication is:

replicaset.rb (recipe) -> uses definition/mongodb ->  calls MongoDB.configure_replicaset (location: library/mongodb.rb)

2) The replicaset_yml.rb

YAML Format is:

test51:
  cluster: nevada
  instance: vegas
  ipaddresses:
    private: 10.0.3.150
    public: 192.168.1.150
test52:
  cluster: nevada
  instance: vegas
  ipaddresses:
    private: 10.0.3.180
    public: 192.168.1.180
test53:
  cluster: nevada
  instance: vegas
  ipaddresses:
    private: 10.0.3.171
    public: 192.168.1.171


The flow is:

replicaset_yml.rb (recipe) -----> calls replicaset_members (location: library/replicaset_ymlconfig)
                  <--------- returns replica boolean(true/false), replicaset_name, members

                           -----> calls configure_replica (location: library/mongodb)

