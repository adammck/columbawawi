class Children < Application
  # provides :xml, :yaml, :js

  def index
    @children = Child.all
    display @children
  end

  def show(id)
    @child = Child.get(id)
    raise NotFound unless @child
    display @child
  end

  def new
    only_provides :html
    @child = Child.new
    display @child
  end

  def edit(id)
    only_provides :html
    @child = Child.get(id)
    raise NotFound unless @child
    display @child
  end

  def create(child)
    @child = Child.new(child)
    if @child.save
      redirect resource(@child), :message => {:notice => "Child was successfully created"}
    else
      message[:error] = "Child failed to be created"
      render :new
    end
  end

  def update(id, child)
    @child = Child.get(id)
    raise NotFound unless @child
    if @child.update_attributes(child)
       redirect resource(@child)
    else
      display @child, :edit
    end
  end

  def destroy(id)
    @child = Child.get(id)
    raise NotFound unless @child
    if @child.destroy
      redirect resource(:children)
    else
      raise InternalServerError
    end
  end

end # Children
