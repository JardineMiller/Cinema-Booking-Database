require_relative('../db/sqlrunner.rb')

class Film
  attr_reader :id, :title
  attr_accessor :price

  def initialize(options)
    @id = options['id'].to_i if options['id']
    @title = options['title']
    @price = options['price'].to_i
  end

  def save
    sql = "
    INSERT INTO films
    (title, price)
    VALUES
    ($1, $2)
    RETURNING id
    "
    values = [@title, @price]
    film = SqlRunner.run(sql, values).first
    @id = film['id'].to_i
  end

  def delete
    sql = "
    DELETE FROM films
    WHERE id = $1
    "
    values = [@id]
    SqlRunner.run(sql, values)
  end

  def update
    sql = "
    UPDATE films
    SET (title, price) = ($1, $2)
    WHERE id = $3
    "
    values = [@title, @price, @id]
    SqlRunner.run(sql, values)
  end

  def customers
    sql = "
    SELECT customers.* FROM tickets
    INNER JOIN screenings
    ON tickets.screening_id = screenings.id
    INNER JOIN customers
    ON tickets.customer_id = customers.id
    WHERE film_id = $1
    "
    values = [@id]
    customers = SqlRunner.run(sql, values)
    result = customers.map { |customer| Customer.new(customer)  }
    return result
  end

  def customer_count
    # sql = "
    # SELECT count(film_id) FROM tickets
    # INNER JOIN screenings
    # ON screening_id = screenings.id
    # WHERE film_id = $1
    # GROUP BY film_id
    # "
    # values = [@id]
    # result = SqlRunner.run(sql, values).first
    # return 0 if result == nil
    # return result['count'].to_i
    return self.customers.count
  end

  def self.all
    sql = "SELECT * FROM films"
    films = SqlRunner.run(sql)
    result = films.map { |film| Film.new(film) }
  end

  def self.delete_all
    sql = "DELETE FROM films"
    SqlRunner.run(sql)
  end

end