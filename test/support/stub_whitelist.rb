module StubWhitelist

  def stub_whitelist(controller_klass, whitelist={})
    controller_klass.stub_any_instance(:get_whitelist, whitelist) do
      yield
    end
  end

end