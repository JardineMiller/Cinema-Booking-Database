require_relative('../db/sqlrunner.rb')

class Screening
  attr_reader :id, :start_time, :film_id
  attr_accessor :empty_seats

  def initialize(options)
    @id = options['id'].to_i if options['id']
    @film_id = options['film_id'].to_i
    @start_time = options['start_time']
    @empty_seats = options['empty_seats'].to_i
  end

  def has_room?
    @empty_seats > 0
  end

  def sell_ticket(customer, screening)
    return "Screening full." if !screening.has_room?
    new_ticket = Ticket.new({'customer_id' => customer.id, 'screening_id' => screening.id})
    screening.empty_seats -= 1
    new_ticket.save
    self.update
  end

  def self.most_popular
    sql = "
    SELECT screening_id, count(screening_id) FROM tickets
    GROUP BY screening_id
    ORDER BY count DESC
    LIMIT 1
    "
    result = SqlRunner.run(sql).first
    screening_id = result['screening_id'].to_i
    Screening.find_by_id(screening_id)
  end

  def self.find_by_id(id)
    sql = "
    SELECT * FROM screenings
    WHERE id = $1
    "
    values = [id]
    screening = SqlRunner.run(sql, values).first
    return false if screening == nil
    return Screening.new(screening)
  end

  def film
    sql = "
    SELECT DISTINCT films.* FROM films
    INNER JOIN screenings
    ON screenings.film_id = films.id
    WHERE films.id = $1
    "
    values = [@film_id]
    film = SqlRunner.run(sql, values).first
    return Film.new(film)
  end

  def save
    sql = "
    INSERT INTO screenings
    (film_id, start_time, empty_seats)
    VALUES
    ($1, $2, $3)
    RETURNING id
    "
    values = [@film_id, @start_time, @empty_seats]
    screening = SqlRunner.run(sql, values).first
    @id = screening['id'].to_i
  end

  def update
    sql = "
    UPDATE screenings
    SET (empty_seats) = ($1)
    WHERE id = $2
    "
    values = [@empty_seats, @id]
    SqlRunner.run(sql, values)
  end

  def delete
    sql = "
    DELETE FROM screenings
    WHERE id = $1
    "
    values = [@id]
    SqlRunner.run(sql, values)
  end

  def self.all
    sql = "SELECT * FROM screenings"
    screenings = SqlRunner.run(sql)
    result = screenings.map { |screening| Screening.new(screening) }
  end

  def self.delete_all
    sql = "DELETE FROM screenings"
    SqlRunner.run(sql)
  end

end