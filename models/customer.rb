require_relative('../db/sqlrunner.rb')

class Customer
  attr_reader :id, :name
  attr_accessor :funds

  def initialize(options)
    @id = options['id'].to_i if options['id']
    @name = options['name']
    @funds = options['funds'].to_i
  end

  def sufficient_funds?(price)
    @funds > price
  end

  def buy_ticket(screening)
    return "Insufficient funds" if !sufficient_funds?(screening.film.price)
    screening.sell_ticket(self, screening)
    @funds -= screening.film.price
    self.update
    return "Purchase successful."
  end

  def ticket_count
    sql = "
    SELECT count(customer_id) FROM tickets
    WHERE customer_id = $1
    GROUP BY customer_id
    "
    values = [@id]
    result = SqlRunner.run(sql, values).first
    return 0 if result == nil
    return result['count'].to_i
  end

  def save
    sql = "
    INSERT INTO customers
    (name, funds)
    VALUES
    ($1, $2)
    RETURNING id
    "
    values = [@name, @funds]
    customer = SqlRunner.run(sql, values).first
    @id = customer['id'].to_i
  end

  def delete
    sql = "
    DELETE FROM customers
    WHERE id = $1
    "
    values = [@id]
    SqlRunner.run(sql, values)
  end

  def films
    sql = "
    SELECT films.* FROM films
    INNER JOIN tickets
    ON tickets.film_id = films.id
    WHERE tickets.customer_id = $1
    "
    values = [@id]
    films = SqlRunner.run(sql, values)
    result = films.map { |film| Film.new(film)  }
    return result
  end

  def update
    sql = "
    UPDATE customers
    SET (name, funds) = ($1, $2)
    WHERE id = $3
    "
    values = [@name, @funds, @id]
    SqlRunner.run(sql, values)
  end

  def self.all
    sql = "SELECT * FROM customers"
    customers = SqlRunner.run(sql)
    result = customers.map { |customer| Customer.new(customer) }
  end

  def self.delete_all
    sql = "DELETE FROM customers"
    SqlRunner.run(sql)
  end


  
end