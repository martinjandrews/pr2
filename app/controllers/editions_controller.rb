class EditionsController < ApplicationController
  before_action :set_edition, only: [:show, :edit, :update, :destroy]

  # GET /editions
  # GET /editions.json
  def index
    @editions = Edition.all
  end

  # GET /editions/1
  # GET /editions/1.json
  def show
    @placings = Placing.all
    @players = Player.all
  end

  # GET /editions/new
  def new
    @edition = Edition.new
    @edition.tournament = Tournament.find(params[:tournament_id])
  end

  # GET /editions/1/edit
  def edit
  end

  # POST /editions
  # POST /editions.json
  def create
    @edition = Edition.new(edition_params)

    respond_to do |format|
      if @edition.save
        format.html { redirect_to @edition.tournament, notice: 'Edition was successfully created.' }
        format.json { render :show, status: :created, location: @edition }
      else
        format.html { render :new }
        format.json { render json: @edition.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /editions/1
  # PATCH/PUT /editions/1.json
  def update
    respond_to do |format|
      if @edition.update(edition_params)
        format.html { redirect_to @edition.tournament, notice: 'Edition was successfully updated.' }
        format.json { render :show, status: :ok, location: @edition }
      else
        format.html { render :edit }
        format.json { render json: @edition.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /editions/1
  # DELETE /editions/1.json
  def destroy
    tournament = @edition.tournament
    @edition.destroy
    respond_to do |format|
      format.html { redirect_to tournament, notice: 'Edition was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_edition
      @edition = Edition.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def edition_params
      params.require(:edition).permit(:year, :start_date, :end_date, :multiplier, :tournament_id)
    end
end
