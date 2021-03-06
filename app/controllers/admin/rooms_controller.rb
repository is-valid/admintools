class Admin::RoomsController < Admin::AppAdminController
  before_filter :user_all, :only => [:index, :new, :edit, :create, :update]
  before_filter :current_room, :only => [:show, :edit, :update, :destroy]

  def index
    @search = Room.search(params[:search] || {"meta_sort" => "id.asc"})
    @rooms = @search.includes(:user).paginate(:page => params[:page]).order('created_at').all
  end

  def new
    @room = Room.new
    @room.build_room_plan
  end

  def show
  end

  def edit
  end

  def create
    @room = Room.new(params[:room])
    if @room.save
      redirect_to :admin_root, :notice => t(:'admin.rooms.create.created', :name => @room.name)
    else
      render :action => "new"
    end
  end

  def update
    if @room.update_attributes(params[:room])
      redirect_to :admin_root, :notice => t(:'admin.rooms.update.updated', :name => @room.name)
    else
      render :action => "edit"
    end
  end

  def destroy
    @room.destroy and redirect_to :admin_root, :notice => t(:'admin.rooms.destroy.destroyed', :name => @room.name)
  end

  private

  def user_all
    @users ||= User.all
  end

  def current_room
    @room = Room.find(params[:id])
  end
end