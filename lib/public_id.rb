module PublicId

  def self.included(base)
    base.send("primary_key=", :public_id)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods

    def has_public_id
      before_create :generate_public_id
    end

    def from_param(param)
      find_by_public_id(param)
    end
  end

  module InstanceMethods
    def generate_public_id
      self.public_id = 1_000_000 + Random.rand(10_000_000 - 1_000_000)
      generate_public_id if self.class.exists?(public_id: self.public_id)
    end

    def to_param
      public_id
    end
  end
end
