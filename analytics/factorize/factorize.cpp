#include <iostream>
#include <string>
#include <vector>
#include <stack>

using namespace std;

void findprimes(int &num, vector<int> &primes)
{
  // Special starting case.
  if (primes.size() == 0)
    primes.push_back(2);

  // Add primes, if needed.
  while (primes[primes.size() - 1] <= num/2)
  {
    // Determine if a particular number is a prime.
    int count = primes[primes.size() - 1] + 1;
    while (true)
    {
      bool divideable = false;
      for (int i = 0; i < primes.size(); i++)
        if (count % primes[i] == 0)
          divideable = true;

      if (divideable)
        count++;
      else
        break;
    }
    primes.push_back(count);
  }
}

void factorize(int &num, vector<int> &primes, vector<int> &factors)
{
  if (num == 1)
  {
    factors.push_back(1);
    return;
  }

  bool changed = true;
  while (changed)
  {
    changed = false;

    for (int i = 0; i < primes.size(); i++)
    {
      if (primes[i] > num/2)
        break;
      if (num % primes[i] == 0)
      {
        factors.push_back(primes[i]);
        num = num / primes[i];
        changed = true;
        break;
      }
    }
  }
  if (num != 1)
    factors.push_back(num);
}

int main()
{
    int num;
    vector<int> primes;
    vector<int> factors;

    while (true)
    {
      // Prep variables.
      num = 0;
      factors.clear();

      // Get input.
      cout << "Enter a number: ";
      cin >> num;

      // Process input.
      if (num < 1)
        break;
      else
      {
        findprimes(num, primes);
        factorize(num, primes, factors);
      }

      // DEBUG. Display primes.
      //for (int i = 0 ; i < primes.size(); i++)
      //  cout << "\033[1;31m" << primes[i] << "\033[0m\n";

      // Display output.
      for (int i = 0 ; i < factors.size(); i++)
        cout << factors[i] << endl;
    }

    cout << "Bye.";
    return 0;
}
