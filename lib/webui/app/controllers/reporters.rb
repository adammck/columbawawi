class Reporters < Application
  # provides :xml, :yaml, :js

  def index
    @reporters = Reporter.all
    display @reporters
  end

  def show(id)
    @reporter = Reporter.get(id)
    raise NotFound unless @reporter
    display @reporter
  end

  def new
    only_provides :html
    @reporter = Reporter.new
    display @reporter
  end

  def edit(id)
    only_provides :html
    @reporter = Reporter.get(id)
    raise NotFound unless @reporter
    display @reporter
  end

  def create(reporter)
    @reporter = Reporter.new(reporter)
    if @reporter.save
      redirect resource(@reporter), :message => {:notice => "Reporter was successfully created"}
    else
      message[:error] = "Reporter failed to be created"
      render :new
    end
  end

  def update(id, reporter)
    @reporter = Reporter.get(id)
    raise NotFound unless @reporter
    if @reporter.update_attributes(reporter)
       redirect resource(@reporter)
    else
      display @reporter, :edit
    end
  end

  def destroy(id)
    @reporter = Reporter.get(id)
    raise NotFound unless @reporter
    if @reporter.destroy
      redirect resource(:reporters)
    else
      raise InternalServerError
    end
  end

end # Reporters
