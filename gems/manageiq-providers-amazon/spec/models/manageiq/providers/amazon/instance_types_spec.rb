describe ManageIQ::Providers::Amazon::InstanceTypes do
  class Attribute
    attr_accessor :key, :key_other, :processor, :other_proc
    def initialize(key, key_other = nil, &processor)
      self.key = key
      self.key_other = key_other || key
      self.processor = processor
    end

    def other_proc(&block)
      self.other_proc = block
      self
    end

    def fetch(instance, key)
      if processor
        processor.call(instance.fetch(key))
      else
        instance.fetch(key)
      end
    end

    def same?(a, other)
      fetch(a, key) == fetch(other, key_other)
    end

    def format(instance)
      %Q(:#{key} => "#{fetch(instance, key_other)}")
    end
  end

  def format_instance(instance, attributes)
    puts %Q("#{instance[:instance_type]}" => {)
    attributes.each do |key|
      puts key.format(instance)
    end
    puts '}'
  end

  it "is the same" do
    require 'open-uri'

    attributes = [
      Attribute.new(:name, :instance_type),
      Attribute.new(:family) {|a| a.downcase},
      Attribute.new(:description, :pretty_name) {|a| a.downcase},
      Attribute.new(:memory).other_proc{|b| b.to_f.gigabytes }
    ]

    find_instance = Proc.new do |o|
      described_class.all.find do |i|
        attributes.all?{|a| a.same?(i, o)}
      end
    end

    # instances = YAML.safe_load(open('https://raw.githubusercontent.com/powdahound/ec2instances.info/master/www/instances.json').read)
    instances = YAML.safe_load(open('/tmp/instances.json').read)
    instances.each do |instance|
      instance.deep_symbolize_keys!
      find_instance.call(instance) or format_instance(instance, attributes)
    end

  end

end
