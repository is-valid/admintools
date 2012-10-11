# encoding: UTF-8
class PollController < ApplicationController

  helper_method :total_voted, :opt_voted, :voted_set

  def opt_voted(opt,i,poll)
    poll.voteds.find_all_by_option_vote_and_option_id(opt,i+1).count
  end

  def total_voted(poll)
    poll.voteds
  end

  def voted_set(poll)
    poll.voteds.find_by_user_id(current_user.id)
  end

  def index
    @polls = Poll.all
  end

  def new
    @poll = Poll.new
  end

  def create
    if !params['poll']['question'].blank? && params['poll']['max_votes'].to_i > 0 && params['poll']['option'].delete_if {|x| x == "" }.count > 1
      @poll = Poll.create(params['poll'])
      @poll.update_attribute(:end_at, 1.day.from_now) if @poll.end_at < DateTime.now
      redirect_to poll_index_path
    else
      flash[:notice] = "Неверно введены данные."
      redirect_to new_poll_path
    end
  end

  def show
    redirect_to poll_index_path if (@poll = Poll.find_by_id(params['id'])).blank?
  end

  def voted
    if (@poll = Poll.find_by_id(params['id'])).blank?
      redirect_to poll_index_path
    else
      if !params['option'].blank? && params['option'].count <= @poll.max_votes
        params['option'].each do |opt|
          @voted = Voted.find_or_create_by_user_id_and_poll_id_and_option_vote_and_option_id(:user_id => current_user.id, :poll_id => @poll.id, :option_vote => opt.last["name"], :option_id => opt.first.to_i+1)
        end
      else
        flash[:notice] = "Неверное количество голосов, минимум 1, максимум #{@poll.max_votes}."
      end
      redirect_to poll_path(@poll)
    end
  end

end