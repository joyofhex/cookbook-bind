unified_mode true

describe port(53) do
  it { should be_listening }
  its('processes') { should include 'named' }
end

describe command('rndc reload') do
  its('exit_status') { should eq 0 }
  its('stdout') { should eq "server reload successful\n" }
end

describe command('host ns1.example.com 127.0.0.1') do
  its('exit_status') { should eq 0 }
  its('stdout') { should include 'ns1.example.com has address 1.1.1.1' }
end
