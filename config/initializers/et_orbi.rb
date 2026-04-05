class EtOrbi::EoTime
  def to_time
    Time.at(self.to_i)
  end
end
