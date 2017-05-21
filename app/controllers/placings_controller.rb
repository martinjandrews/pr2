class PlacingsController < ApplicationController
  before_action :set_placing, only: [:show, :edit, :update, :destroy]

  # GET /placings
  # GET /placings.json
  def index
    @placings = Placing.all
  end

  # GET /placings/1
  # GET /placings/1.json
  def show
  end

  # GET /placings/new
  def new
    @placing = Placing.new
  end

  # GET /placings/1/edit
  def edit
  end

  # POST /placings
  # POST /placings.json
  def create
    @placing = Placing.new(placing_params)

    respond_to do |format|
      if @placing.save
        format.html { redirect_to @placing, notice: 'Placing was successfully created.' }
        format.json { render :show, status: :created, location: @placing }
      else
        format.html { render :new }
        format.json { render json: @placing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /placings/1
  # PATCH/PUT /placings/1.json
  def update
    respond_to do |format|
      if @placing.update(placing_params)
        format.html { redirect_to @placing, notice: 'Placing was successfully updated.' }
        format.json { render :show, status: :ok, location: @placing }
      else
        format.html { render :edit }
        format.json { render json: @placing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /placings/1
  # DELETE /placings/1.json
  def destroy
    @placing.destroy
    respond_to do |format|
      format.html { redirect_to placings_url, notice: 'Placing was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_placing
      @placing = Placing.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def placing_params
      params.require(:placing).permit(:position, :edition_id, :player_id)
    end
end
