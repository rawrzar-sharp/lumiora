import logo from './logo.svg';
import './App.css';
import { useState, useEffect } from "react";
function Home({ loggedInUser }) {
  const [users, setUsers] = useState([]);

  useEffect(() => {
    console.log("hello this is called after web is loaded")

    fetch('https://jsonplaceholder.typicode.com/users')
      .then(response => response.json())
      .then(json => setUsers(json))
  }, []);

  return (
    <div>
      Hello, {loggedInUser}
      <table>
        <thead>
          <tr>
            <th>Id</th>
            <th>Name</th>
            <th>Email</th>
          </tr>
        </thead> 
        <tbody>
          {
            users.map(user => (
              <tr key={user.id}>
                <td>{user.id}</td>
                <td>{user.email}</td>
                <td>{user.email}</td>
              </tr>
            ))
          }
        </tbody>
      </table>
    </div>
  )
}

function Header(props) {
  return (
    <ul>
      <li>Home</li>
      <li>Products</li>
      <li>Reports</li>
    </ul>
  )
}

function App() {
  return (
    <div className="App">
      <Home loggedInUser="Bambang" />
      <Header />
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          hello test
        </a>
      </header>
    </div>
  );
}

export default App;
