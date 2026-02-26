defmodule TodoBuddy.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do

    execute """
    CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      username VARCHAR(255) NOT NULL UNIQUE,
      email VARCHAR(255) NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """

    execute """
    DO $$ BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'todo_status') THEN
        CREATE TYPE todo_status AS ENUM ('in-progress', 'on-hold', 'complete');
      END IF;
    END $$
    """

    execute """
    CREATE TABLE IF NOT EXISTS categories (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL UNIQUE,
      display_name VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """

    execute """
    CREATE TABLE IF NOT EXISTS todos (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title TEXT NOT NULL,
      description TEXT,
      status todo_status DEFAULT 'in-progress',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      bookmarked BOOLEAN DEFAULT false,
      user_id UUID REFERENCES users(id),
      category_id INTEGER REFERENCES categories(id),
      rating NUMERIC DEFAULT 0
    )
    """

    execute """
    CREATE TABLE IF NOT EXISTS subtasks (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      todo_id UUID REFERENCES todos(id) ON DELETE CASCADE,
      user_id UUID REFERENCES users(id),
      title VARCHAR(255) NOT NULL,
      description TEXT,
      status VARCHAR(50) DEFAULT 'in-progress',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """
  end
end
